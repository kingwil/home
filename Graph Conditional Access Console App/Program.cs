using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.Graph;
using Microsoft.Graph.Auth;
using Microsoft.Identity.Client;

// Log Analytics Libraries
using System.Net.Http;
using System.Net.Http.Headers;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;

namespace Graph_Conditional_Access_Console_App
{
    class Program
    {
        // An example JSON object, with key/value pairs
        //static string json = @"[{""DemoField1"":""DemoValue1"",""DemoField2"":""DemoValue2""},{""DemoField3"":""DemoValue3"",""DemoField4"":""DemoValue4""}]";
        static string json;
        // Log Analytics workspace ID
        static string customerId = "<guid>";

        // Log Analytics workspace primary or the secondary key   
        static string sharedKey = "<key>";

        // LogName is name of the event type that is being submitted to Azure Monitor
        static string LogName = "NamedLocations";

        // You can use an optional field to specify the timestamp from the data. If the time field is not specified, Azure Monitor assumes the time is the message ingestion time
        //static string TimeStampField = "";

        public static List<TrustedIP> namedLocs = new List<TrustedIP>();

        static async Task Main(string[] args)
        {
            // Azure AD App which is granted Policy.Read.All permissions to Microsoft Graph API
            string clientId = "<guid>";
            string clientSecret = "<secret>";
            string tenantID = "<guid>";

            //Initialize Confidential Client
            IConfidentialClientApplication confidentialClientApplication = ConfidentialClientApplicationBuilder
            .Create(clientId)
            .WithTenantId(tenantID)
            .WithClientSecret(clientSecret)
            .Build();

            // Connect to Graph API
            ClientCredentialProvider authProvider = new ClientCredentialProvider(confidentialClientApplication);
            GraphServiceClient graphClient = new GraphServiceClient(authProvider);

            //Query Conditional Access Named Locations to output CIDR blocks
            var namedLocations = await graphClient.Identity.ConditionalAccess.NamedLocations.Request().GetAsync();

            foreach (NamedLocation location in namedLocations)
            {
                // Conditional access might have country locations defined, so only look for IP named locations
                if(location is Microsoft.Graph.IpNamedLocation)
                {
                    var ranges = ((Microsoft.Graph.IpNamedLocation)location).IpRanges;
                    foreach (IPv4CidrRange ip in ranges)
                    {
                        TrustedIP entry = new TrustedIP();
                        entry.CidrBlock = ((Microsoft.Graph.IPv4CidrRange)ip).CidrAddress;
                        entry.Location = location.DisplayName;
                        namedLocs.Add(entry);
                    }
                }
            }

            json = JsonSerializer.Serialize(namedLocs);

            // Create a hash for the API signature
            var datestring = DateTime.UtcNow.ToString("r");
            var jsonBytes = Encoding.UTF8.GetBytes(json);
            string stringToHash = "POST\n" + jsonBytes.Length + "\napplication/json\n" + "x-ms-date:" + datestring + "\n/api/logs";
            string hashedString = BuildSignature(stringToHash, sharedKey);
            string signature = "SharedKey " + customerId + ":" + hashedString;

            PostData(signature, datestring, json);
        }

        // Build the API signature
        public static string BuildSignature(string message, string secret)
        {
            var encoding = new System.Text.ASCIIEncoding();
            byte[] keyByte = Convert.FromBase64String(secret);
            byte[] messageBytes = encoding.GetBytes(message);
            using (var hmacsha256 = new HMACSHA256(keyByte))
            {
                byte[] hash = hmacsha256.ComputeHash(messageBytes);
                return Convert.ToBase64String(hash);
            }
        }

        // Send a request to the POST API endpoint
        public static void PostData(string signature, string date, string json)
        {
            try
            {
                string url = "https://" + customerId + ".ods.opinsights.azure.com/api/logs?api-version=2016-04-01";

                System.Net.Http.HttpClient client = new System.Net.Http.HttpClient();
                client.DefaultRequestHeaders.Add("Accept", "application/json");
                client.DefaultRequestHeaders.Add("Log-Type", LogName);
                client.DefaultRequestHeaders.Add("Authorization", signature);
                client.DefaultRequestHeaders.Add("x-ms-date", date);
                // client.DefaultRequestHeaders.Add("time-generated-field", TimeStampField);

                System.Net.Http.HttpContent httpContent = new StringContent(json, Encoding.UTF8);
                httpContent.Headers.ContentType = new MediaTypeHeaderValue("application/json");
                Task<System.Net.Http.HttpResponseMessage> response = client.PostAsync(new Uri(url), httpContent);

                System.Net.Http.HttpContent responseContent = response.Result.Content;
                string result = responseContent.ReadAsStringAsync().Result;
                Console.WriteLine("Return Result: " + result);
            }
            catch (Exception excep)
            {
                Console.WriteLine("API Post Exception: " + excep.Message);
            }
        }
    }

    class TrustedIP
    {
        public string CidrBlock { get; set; }
        public string Location { get; set; }
    }
}
