using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace Transcribr.FileUpload.Functions
{
    public class AudioUpload
    {
        private readonly ILogger _logger;

        public AudioUpload(ILoggerFactory loggerFactory)
        {
            _logger = loggerFactory.CreateLogger<AudioUpload>();
        }

        [Function(nameof(AudioUpload))]
        public AudioUploadOutput Run([HttpTrigger(AuthorizationLevel.Anonymous, "get", "post")] HttpRequest req)
        {
            _logger.LogInformation("Processing a new audio file upload request");

            // Get the first file in the form
            byte[]? audioFileData = null;
            var file = req.Form.Files[0];

            using (var memoryStream = new MemoryStream())
            {
                file.OpenReadStream().CopyTo(memoryStream);
                audioFileData = memoryStream.ToArray();
            }

            return new AudioUploadOutput
            {
                Blob = audioFileData,
                HttpResponse = new OkObjectResult("File Uploaded!")
            };
        }
    }

    public class AudioUploadOutput
    {
        [BlobOutput("%STORAGE_ACCOUNT_CONTAINER%/{rand-guid}.wav", Connection = "AudioUploadStorage")]
        public byte[] Blob { get; set; }

        public required IActionResult HttpResponse { get; set; }
    }
}
