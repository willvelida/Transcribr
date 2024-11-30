using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Transcribr.FileProcessor.Models
{
    public class TranscriptionJob
    {
        public string Self { get; set; }

        public string Status { get; set; }

        public TranscriptionJobFiles Links { get; set; }
    }
}
