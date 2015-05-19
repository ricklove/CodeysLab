<%@ WebHandler Language="C#" Class="Handler" %>

using System;
using System.IO;
using System.Web;
using System.Linq;
using System.Collections.Generic;

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
                var logMessage = context.Server.UrlDecode(context.Request.Unvalidated["Log"]);
                var exceptionMessage = context.Server.UrlDecode(context.Request.Unvalidated["Exception"]);
                var stackTrace = context.Server.UrlDecode(context.Request.Unvalidated["StackTrace"]);

                var sendFeedback = qs["SendFeedback"];
                var feedbackData = context.Server.UrlDecode(context.Request.Unvalidated["FeedbackData"]);

                if (logMessage != null)
                {
                    AddToClientLog(clientID.Value, logMessage);
                    message = "OK";
                }
                else if (exceptionMessage != null)
                {
                    AddToClientLog(clientID.Value, exceptionMessage);
                    AddToExceptionLog(clientID.Value, exceptionMessage, stackTrace);
                    message = "OK";
                }
                else if (sendFeedback != null)
                {
                    AddToFeedbackLog(clientID.Value, feedbackData);
                    message = "OK";
                }
            }
        }
        else if (qs["GetReport"] == "VeryYes")
        {
            message = GetReport(qs);
        }

        context.Response.ContentType = "text/plain";
        context.Response.Write(message);
    }

    private string GetReport(System.Collections.Specialized.NameValueCollection qs)
    {
        var message = "";
        var nextClientID = BitConverter.ToUInt64(File.ReadAllBytes(GetNextClientIDPath()), 0);

        var activity = "";
        var lastActivity = new List<DateTime>();

        var shouldGetStepTimes = qs["StepTimes"] != null;
        var stepTimes = new Dictionary<string, StepTime>();

        foreach (var dir in Directory.GetDirectories(ClientDataRootPath))
        {
            foreach (var f in Directory.GetFiles(dir))
            {
                var fileInfo = new FileInfo(f);
                activity += fileInfo.Directory.Name + "\\" + fileInfo.Name + "; Created On = " + fileInfo.CreationTimeUtc + "; Last Modified On = " + fileInfo.LastWriteTimeUtc + "; Length = " + fileInfo.Length + "\r\n";

                if (f.Contains("log.txt"))
                {
                    lastActivity.Add(fileInfo.LastWriteTimeUtc);

                    // Time Reports for each step
                    if (shouldGetStepTimes)
                    {
                        var content = File.ReadAllText(fileInfo.FullName);
                        var timeLines = content.Split(new string[] { "\r\n" }, StringSplitOptions.None).Where(l => l.Contains("time=")).ToList();
                        var timeTexts = timeLines
                            .Select(l => l.Split(new string[] { "time=" }, StringSplitOptions.None)[1])
                            .Select(aPart =>
                            {
                                var i = aPart.IndexOf(';');
                                return new { time = int.Parse(aPart.Substring(0, i)), afterText = aPart.Substring(i + 1).Trim() };
                            })
                            ;


                        foreach (var t in timeTexts)
                        {
                            if (!stepTimes.ContainsKey(t.afterText))
                            {
                                stepTimes.Add(t.afterText, new StepTime(t.afterText));
                            }

                            var stepTime = stepTimes[t.afterText];
                            stepTime.Count++;
                            stepTime.Total += t.time;
                        }

                    }
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
        var clientFeedback = "";
        var activityClientID = qs["ActivityClientID"];
        if (activityClientID != null)
        {
            var path = ClientDataRootPath + "\\" + activityClientID + "\\log.txt";

            if (File.Exists(path))
            {
                clientActivity = File.ReadAllText(path);
            }

            var feedbackPath = ClientDataRootPath + "\\" + activityClientID + "\\feedbackLog.txt";
            if (File.Exists(feedbackPath))
            {
                clientFeedback = File.ReadAllText(feedbackPath);
            }
        }

        // Exception Log
        var exceptionLogPath = ClientDataRootPath + "\\" + "exceptions.txt";
        var exceptionLog = File.Exists(exceptionLogPath) ? File.ReadAllText(exceptionLogPath) : "";

        // Feedback
        var feedbackLogPath = ClientDataRootPath + "\\" + "feedbackLog.txt";
        var feedbackLog = File.Exists(feedbackLogPath) ? File.ReadAllText(feedbackLogPath) : "";
        var feedbackLines = feedbackLog.Replace("\r\n", "\n").Split(new char[] { '\n' }, StringSplitOptions.RemoveEmptyEntries);
        var feedbackEntries = feedbackLines
            .Where(l => l.StartsWith("\t"))
            .Select(l => new { iEquals = l.IndexOf("="), line = l })
            .Select(l => new { key = l.line.Substring(0, l.iEquals).Trim(), value = l.line.Substring(l.iEquals + 1).Trim() });

        var feedbackGroups = feedbackEntries.GroupBy(e => e.key)
            .Select(g => new { g.Key, Values = g.GroupBy(gv => gv.value).Select(gv => new { Value = gv.Key, Count = gv.Count(), Ratio = gv.Count() * 1.0 / g.Count() }) });

        // Message
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

        // Feedback
        foreach (var f in feedbackGroups)
        {
            message += f.Key;
            message += "\r\n";

            foreach (var fv in f.Values)
            {
                message += "\t" + fv.Ratio.ToString("0.0%") + "\t" + fv.Value;
                message += "\r\n";
            }

            message += "\r\n";
        }

        // Step Times
        if (stepTimes != null)
        {
            var values = stepTimes.Values.OrderByDescending(v => v.Text).ToList();
            foreach (var sTimes in values)
            {
                message += "Average Time = " + sTimes.Average.ToString("f1") + " for " + sTimes.Text;
                message += "\r\n";
            }

            message += "\r\n";

            values = stepTimes.Values.OrderByDescending(v => v.Average).ToList();
            foreach (var sTimes in values)
            {
                message += "Average Time = " + sTimes.Average.ToString("f1") + " for " + sTimes.Text;
                message += "\r\n";
            }

            message += "\r\n";
        }

        if (clientActivity != "" || clientFeedback != "")
        {
            message += "\r\n";
            message += "\r\n";
            message += "\r\n";
            message += "Activity for ClientID = " + activityClientID;
            message += "\r\n";
            message += "\r\n";
            message += clientActivity;
            message += "\r\n";
            message += "\r\n";
            message += "Feedback ClientID = " + activityClientID;
            message += "\r\n";
            message += "\r\n";
            message += clientFeedback;
        }


        message += "\r\n";
        message += "\r\n";
        message += "EXCEPTIONS:";
        message += "\r\n";
        message += exceptionLog;
        message += "\r\n";

        return message;
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
        var path = GetNextClientIDPath();

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

    private string GetNextClientIDPath()
    {
        var path = ClientDataRootPath + "\\nextClientID.ulong.bin";

        //// This should always exist (after initial creation)
        //if (!File.Exists(path))
        //{
        //    File.WriteAllBytes(path, BitConverter.GetBytes((ulong)10));
        //}

        return path;
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

        var fixedMessage = message;//DecodeMessage(message);

        var normalized = fixedMessage.Replace("\r", "\\r").Replace("\n", "\\n").Replace("\t", "\\t") + "\r\n";
        var time = DateTime.UtcNow.ToShortDateString() + "\t" + DateTime.UtcNow.ToShortTimeString();

        File.AppendAllText(path, time + "\t" + normalized);
    }

    public void AddToExceptionLog(ulong clientID, string message, string stackTrace)
    {
        var dir = ClientDataRootPath + "\\";
        var path = dir + "exceptions.txt";

        var fixedMessage = message;//DecodeMessage(message);
        var stackTraceFormatted = (" " + stackTrace).Replace(" at ", "\r\n\tat ").Replace(" in ", "\r\n\tin ") + "\r\n\r\n";

        var normalized = fixedMessage.Replace("\r", "\\r").Replace("\n", "\\n").Replace("\t", "\\t") + "\r\n";
        var time = DateTime.UtcNow.ToShortDateString() + "\t" + DateTime.UtcNow.ToShortTimeString();

        File.AppendAllText(path, time + "\t" + clientID + "\t" + normalized + "\r\n\t" + stackTraceFormatted);
    }

    public void AddToFeedbackLog(ulong clientID, string feedbackData)
    {
        // Add to client feedback log
        var dir = ClientDataRootPath + "\\" + clientID + "\\";
        var path = dir + "feedbackLog.txt";

        var normalized = "\r\n\t" + feedbackData.Replace("\n", "\n\t") + "\r\n";
        var time = DateTime.UtcNow.ToShortDateString() + "\t" + DateTime.UtcNow.ToShortTimeString();

        File.AppendAllText(path, time + normalized);

        // Add to primary feedback log
        path = ClientDataRootPath + "\\" + "feedbackLog.txt";
        File.AppendAllText(path, time + normalized);
    }

    //public static string DecodeMessage(string message)
    //{
    //    // Fix bugs in Unity encoder
    //    return message.Replace("%3C", "<");
    //}


    public class StepTime
    {
        public int Count { get; set; }
        public long Total { get; set; }

        public double Average { get { return Total * 1.0 / Count; } }

        public string Text { get; private set; }

        public StepTime(string text)
        {
            Text = text;
        }
    }

}