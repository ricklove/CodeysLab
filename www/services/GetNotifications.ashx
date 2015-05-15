<%@ WebHandler Language="C#" Class="Handler" %>

using System;
using System.Web;

public class Handler : IHttpHandler
{
    public void ProcessRequest(HttpContext context)
    {
        context.Response.ContentType = "text/plain";
        context.Response.Write(NotificationMessage);
    }

    public bool IsReusable
    {
        get
        {
            return true;
        }
    }

    public static string NotificationMessage = @"
# 2015-05-15 11:08
## TITLE: Codey's Lab Framework Completed
## IMAGE: http://codeyslab.com/notifications/images/codeyslablogo.png
## LINK: http://codeyslab.com/notifications/2015-05-15_FrameworkCompleted/
## MESSAGE:
Codey's Lab is released!
Check it out!
";
}