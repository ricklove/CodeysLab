<%@ WebHandler Language="C#" Class="Handler" %>

using System;
using System.IO;
using System.Web;
using System.Linq;

public class Handler : IHttpHandler
{
    private Random _rand = new Random();

    public void ProcessRequest(HttpContext context)
    {
        var qs = context.Request.QueryString;
        var message = "";

        if (qs["GetClientID"] != null)
        {
            var idKey = GetNextClientIDAndKey();
            message = idKey;
        }
        else if (qs["ClientID"] != null)
        {
            var clientID = VerifyClientID(qs["ClientID"], qs["ClientKey"]);

            if (clientID != null)
            {
                if (qs["Log"] != null)
                {
                    AddToClientLog(clientID.Value, qs["Log"]);
                    message = "OK";
                }
            }
        }
        else if (qs["GetReport"] == "VeryYes")
        {
            var nextClientID = BitConverter.ToUInt64(File.ReadAllBytes(ClientDataRootPath + "\\nextClientID.bin"), 0);

            var activity = "";
            var lastActivity = new System.Collections.Generic.List<DateTime>();

            foreach (var dir in Directory.GetDirectories(ClientDataRootPath))
            {
                foreach (var f in Directory.GetFiles(dir))
                {
                    var fileInfo = new FileInfo(f);
                    activity += fileInfo.Directory.Name + "\\" + fileInfo.Name + "; Created On = " + fileInfo.CreationTimeUtc + "; Last Modified On = " + fileInfo.LastWriteTimeUtc + "; Length = " + fileInfo.Length + "\r\n";

                    if (f.Contains("log.txt"))
                    {
                        lastActivity.Add(fileInfo.LastWriteTimeUtc);
                    }
                }
            }

            var now = DateTime.UtcNow;
            var past1Hour = now - new TimeSpan(1, 0, 0);
            var past6Hours = now - new TimeSpan(6, 0, 0);
            var past24Hours = now - new TimeSpan(1, 0, 0, 0);
            var past1Week = now - new TimeSpan(7, 0, 0, 0);
            var past4Weeks = now - new TimeSpan(28, 0, 0, 0);
            var past12Weeks = now - new TimeSpan(84, 0, 0, 0);
            var pastYear = now - new TimeSpan(365, 0, 0, 0);

            // Specific client activity
            var clientActivity = "";
            if (qs["ClientID"] != null)
            {
                var path = ClientDataRootPath + "\\" + qs["ClientID"] + "\\";
                clientActivity = File.ReadAllText(path);
            }

            message += "Next Client ID = " + nextClientID + "\r\n";
            message += "\r\n";
            message += lastActivity.Where(a => a > past1Hour).Count() + " Users Active in Past 1 Hour\r\n";
            message += lastActivity.Where(a => a > past6Hours).Count() + " Users Active in Past 6 Hours\r\n";
            message += lastActivity.Where(a => a > past24Hours).Count() + " Users Active in Past 24 Hours\r\n";
            message += lastActivity.Where(a => a > past1Week).Count() + " Users Active in Past 1 Week\r\n";
            message += lastActivity.Where(a => a > past4Weeks).Count() + " Users Active in Past 4 Weeks\r\n";
            message += lastActivity.Where(a => a > past12Weeks).Count() + " Users Active in Past 12 Weeks\r\n";
            message += lastActivity.Where(a => a > pastYear).Count() + " Users Active in Past 1 Year\r\n";
            message += lastActivity.Count() + " Users Active Forever\r\n";
            message += "\r\n";
            message += activity;
            
            message += "\r\n";
            message += "\r\n";
            message += "\r\n";
            message += "Activity forClientID = " + qs["ClientID"];
            message += "\r\n";
            message += "\r\n";

            message += clientActivity;
        }

        context.Response.ContentType = "text/plain";
        context.Response.Write(message);
    }

    public bool IsReusable
    {
        get
        {
            return true;
        }
    }

    public string _clientDataRootPath;
    public string ClientDataRootPath
    {
        get
        {
            if (_clientDataRootPath == null)
            {
                _clientDataRootPath = HttpContext.Current.Server.MapPath("/ClientData");

            }

            return _clientDataRootPath;
        }
    }

    public string GetNextClientIDAndKey()
    {
        var path = ClientDataRootPath + "\\nextClientID.bin";

        // This should always exist (after initial creation)
        //if (!File.Exists(path))
        //{
        //    File.WriteAllBytes(path, BitConverter.GetBytes((ulong)1));
        //}

        var binNextID = File.ReadAllBytes(path);
        var clientID = BitConverter.ToUInt64(binNextID, 0);

        // Increment Next ID
        var binNewNextID = BitConverter.GetBytes(clientID + 1);
        File.WriteAllBytes(path, binNewNextID);

        // Create User Key
        var dir = ClientDataRootPath + "\\" + clientID + "\\";
        if (Directory.Exists(dir))
        {
            // Big problem
            throw new InvalidOperationException("This user already exists!");
        }
        else
        {
            Directory.CreateDirectory(dir);
            var key = _rand.Next();
            File.WriteAllBytes(dir + "key.bin", BitConverter.GetBytes(key));
            return clientID + "_" + key;
        }
    }

    public int? GetClientKey(ulong clientID)
    {
        var dir = ClientDataRootPath + "\\" + clientID + "\\";
        if (Directory.Exists(dir))
        {
            return BitConverter.ToInt32(File.ReadAllBytes(dir + "key.bin"), 0);
        }

        return null;
    }

    public ulong? VerifyClientID(string clientIDText, string clientKey)
    {
        ulong clientID;
        if (!ulong.TryParse(clientIDText, out clientID))
        {
            return null;
        }

        var expectedKey = GetClientKey(clientID);

        if (expectedKey != null && ("" + expectedKey) == clientKey)
        {
            return clientID;
        }

        return null;
    }

    // Logging
    public void AddToClientLog(ulong clientID, string message)
    {
        var dir = ClientDataRootPath + "\\" + clientID + "\\";
        var path = dir + "log.txt";

        var fixedMessage = DecodeMessage(message);

        var normalized = fixedMessage.Replace("\r", "\\r").Replace("\n", "\\n").Replace("\t", "\\t") + "\r\n";
        var time = DateTime.UtcNow.ToShortDateString() + "\t" + DateTime.UtcNow.ToShortTimeString();

        File.AppendAllText(path, time + "\t" + normalized);
    }

    public static string DecodeMessage(string message)
    {
        // Fix bugs in Unity encoder
        return message.Replace("%3C", "<");
    }

}