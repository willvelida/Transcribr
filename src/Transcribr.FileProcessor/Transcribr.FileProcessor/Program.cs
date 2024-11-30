using Azure.Identity;
using Azure.Storage.Blobs;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Transcribr.FileProcessor.Services;
using Transcribr.FileProcessor.Services.Interfaces;

var host = new HostBuilder()
    .ConfigureFunctionsWebApplication()
    .ConfigureAppConfiguration(config =>
    {
        config.AddJsonFile("appsettings.json", optional: true, reloadOnChange: true);
        config.AddEnvironmentVariables();
    })
    .ConfigureServices(services =>
    {
        services.AddSingleton(sp =>
        {
            return new BlobServiceClient(new Uri(Environment.GetEnvironmentVariable("STORAGE_ACCOUNT_URL")), new DefaultAzureCredential());
        });
        services.AddSingleton(sp =>
        {
            var blobServiceClient = sp.GetRequiredService<BlobServiceClient>();
            return blobServiceClient.GetBlobContainerClient(Environment.GetEnvironmentVariable("STORAGE_ACCOUNT_CONTAINER"));
        });
        services.AddSingleton<ISpeechToTextService, SpeechToTextService>();
        services.AddApplicationInsightsTelemetryWorkerService();
        services.ConfigureFunctionsApplicationInsights();
    })
    .Build();

host.Run();
