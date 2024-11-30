using Azure.Storage.Blobs;
using Azure.Storage.Sas;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.DurableTask;
using Microsoft.DurableTask.Client;
using Microsoft.Extensions.Logging;
using Transcribr.FileProcessor.Models;
using Transcribr.FileProcessor.Services.Interfaces;

namespace Transcribr.FileProcessor.Functions
{
    public class AudioTranscriptionOrchestration
    {
        private ILogger _logger;
        private readonly BlobServiceClient _blobServiceClient;
        private readonly BlobContainerClient _blobContainerClient;
        private readonly ISpeechToTextService _speechToTextService;

        public AudioTranscriptionOrchestration(ILoggerFactory loggerFactory, BlobServiceClient blobServiceClient, BlobContainerClient blobContainerClient, ISpeechToTextService speechToTextService)
        {
            _logger = loggerFactory.CreateLogger<AudioTranscriptionOrchestration>();
            _blobServiceClient = blobServiceClient;
            _blobContainerClient = blobContainerClient;
            _speechToTextService = speechToTextService;
        }

        [Function(nameof(AudioBlobUploadStart))]
        public async Task AudioBlobUploadStart(
            [BlobTrigger("%STORAGE_ACCOUNT_CONTAINER%/{name}", Source = BlobTriggerSource.EventGrid, Connection = "STORAGE_ACCOUNT_EVENT_GRID")] Stream stream, string name,
            [DurableClient] DurableTaskClient client,
            FunctionContext executionContext)
        {
            _logger = executionContext.GetLogger(nameof(AudioBlobUploadStart));
            _logger.LogInformation($"Processing audio file: \n Name:{name} \n Size: {stream.Length} Bytes");

            var blobClient = _blobContainerClient.GetBlobClient(name); 

            var userDelegationKey = _blobServiceClient.GetUserDelegationKey(DateTimeOffset.UtcNow, DateTimeOffset.UtcNow.AddMinutes(10));

            var sasBuilder = new BlobSasBuilder()
            {
                BlobContainerName = blobClient.BlobContainerName,
                BlobName = blobClient.Name,
                Resource = "b",
                StartsOn = DateTimeOffset.UtcNow,
                ExpiresOn = DateTimeOffset.UtcNow.AddHours(2)
            };

            sasBuilder.SetPermissions(BlobSasPermissions.Read);

            var blobUriBuilder = new BlobUriBuilder(blobClient.Uri)
            {
                Sas = sasBuilder.ToSasQueryParameters(userDelegationKey, _blobServiceClient.AccountName)
            };

            var audioFile = new AudioFile
            {
                Id = Guid.NewGuid().ToString(),
                Path = blobClient.Uri.ToString(),
                UrlWithSasToken = blobUriBuilder.ToUri().ToString()
            };

            _logger.LogInformation($"Processing audio file {audioFile.Id}");

            string instanceId = await client.ScheduleNewOrchestrationInstanceAsync(nameof(AudioTranscriptionOrchestration), audioFile);

            _logger.LogInformation($"Started orchestration with ID = '{instanceId}'.");
        }

        [Function(nameof(AudioTranscriptionOrchestration))]
        public async Task RunOrchestrator(
            [OrchestrationTrigger] TaskOrchestrationContext context,
            AudioFile audioFile)
        {
            _logger = context.CreateReplaySafeLogger(nameof(AudioTranscriptionOrchestration));
            if (!context.IsReplaying)
            {
                _logger.LogInformation($"Starting transcription for {audioFile.Id}");
            }

            // Start Transcription
            var jobUri = await context.CallActivityAsync<string>(nameof(StartTranscription), audioFile);
            audioFile.JobUri = jobUri;

            DateTime endTime = context.CurrentUtcDateTime.AddMinutes(2);

            while (context.CurrentUtcDateTime < endTime)
            {
                // Check if transcription is done
                var status = await context.CallActivityAsync<string>(nameof(CheckTranscriptionStatus), audioFile);

                if (!context.IsReplaying)
                {
                    _logger.LogInformation($"Status of the transcription {audioFile.Id}: {status}");
                }

                if (status == "Succeeded" || status == "Failed")
                {
                    // Get the transcription
                    string transcription = await context.CallActivityAsync<string>(nameof(GetTranscription), audioFile);

                    if (!context.IsReplaying)
                    {
                        _logger.LogInformation($"Retrieved transcription of {audioFile.Id}: {transcription}");

                    }

                    var audioTranscription = new AudioTranscription
                    {
                        Id = audioFile.Id,
                        Path = audioFile.Path,
                        Result = transcription,
                        Status = status,
                    };

                    // Enrich the transcription
                    if (!context.IsReplaying)
                    {
                        _logger.LogInformation($"Enrich transcription of {audioFile.Id} to Cosmos DB");
                    }

                    // Save the transcription
                    await context.CallActivityAsync(nameof(SaveTranscription), audioTranscription);

                    if (!context.IsReplaying)
                    {
                        _logger.LogInformation($"Saved transcription, finishing processing of {audioFile.Id}");
                    }

                    break;
                }
                else
                {
                    // wait for the next checkpoint
                    var nextCheckpoint = context.CurrentUtcDateTime.AddSeconds(5);
                    if (!context.IsReplaying)
                    {
                        _logger.LogInformation($"Waiting for the next checkpoint for {audioFile.Id} at {nextCheckpoint}");
                    }

                    await context.CreateTimer(nextCheckpoint, CancellationToken.None);
                }
            }
        }

        [Function(nameof(StartTranscription))]
        public async Task<string> StartTranscription([ActivityTrigger] AudioFile audioFile, FunctionContext executionContext)
        {
            _logger = executionContext.GetLogger(nameof(StartTranscription));
            _logger.LogInformation($"Starting transcription for {audioFile.Id}");


            var jobUri = await _speechToTextService.CreateBatchTranscription(audioFile.UrlWithSasToken, audioFile.Id);

            _logger.LogInformation($"Job Uri for {audioFile.Id}: {jobUri}");

            return jobUri;
        }

        [Function(nameof(CheckTranscriptionStatus))]
        public async Task<string> CheckTranscriptionStatus([ActivityTrigger] AudioFile audioFile, FunctionContext executionContext)
        {
            _logger = executionContext.GetLogger(nameof(CheckTranscriptionStatus));
            _logger.LogInformation($"Checking transcription status for {audioFile.Id}");
            var status = await _speechToTextService.GetBatchTranscriptionStatus(audioFile.JobUri);
            _logger.LogInformation($"Transcription status for {audioFile.Id}: {status}");
            return status;
        }

        [Function(nameof(GetTranscription))]
        public async Task<string> GetTranscription([ActivityTrigger] AudioFile audioFile, FunctionContext executionContext)
        {
            _logger = executionContext.GetLogger(nameof(GetTranscription));
            var transcription = await _speechToTextService.GetTranscription(audioFile.JobUri!);
            _logger.LogInformation($"Transcription of {audioFile.Id}: {transcription}");
            return transcription;
        }

        [Function(nameof(EnrichTranscription))]
        public AudioTranscription EnrichTranscription([ActivityTrigger] AudioTranscription audioTranscription, FunctionContext executionContext)
        {
            _logger = executionContext.GetLogger(nameof(EnrichTranscription));
            _logger.LogInformation($"Enriching transcription {audioTranscription.Id}");
            return audioTranscription;
        }

        [Function(nameof(SaveTranscription))]
        [CosmosDBOutput("%COSMOS_DB_DATABASE_NAME%",
            "%COSMOS_DB_CONTAINER_ID%",
            Connection = "COSMOS_DB",
            CreateIfNotExists = true)]
        public AudioTranscription SaveTranscription([ActivityTrigger] AudioTranscription audioTranscription, FunctionContext executionContext)
        {
            _logger = executionContext.GetLogger(nameof(SaveTranscription));
            _logger.LogInformation("Saving the audio transcription..");

            return audioTranscription;
        }
    }
}
