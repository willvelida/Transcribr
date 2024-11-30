using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Transcribr.FileProcessor.Models;

namespace Transcribr.FileProcessor.Services.Interfaces
{
    public interface ISpeechToTextService
    {
        Task<string> CreateBatchTranscription(string audioBlobSasUri, string? id);
        Task<string> GetBatchTranscriptionStatus(string jobUrl);
        Task<string> GetTranscription(string jobUrl);

    }
}
