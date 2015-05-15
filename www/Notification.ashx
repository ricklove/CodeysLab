<%@ WebHandler Language="C#" Class="Handler" %>

using System;
using System.IO;
using System.Web;
using System.Collections.Generic;

public class Handler : IHttpHandler
{
    public void ProcessRequest(HttpContext context)
    {
        var qs = context.Request.QueryString;
        var notificationName = qs["name"];
        var path = GetNotificationPath(notificationName);

        if (!File.Exists(path))
        {
            throw new ArgumentException("Notification Name not found: \"" + notificationName + "\'");
        }

        context.Response.ContentType = "text/html";
        context.Response.Write(GetNotificationHtml(notificationName));
    }

    public bool IsReusable
    {
        get
        {
            return true;
        }
    }

    public static Dictionary<string, string> _notificationHtmls = new Dictionary<string, string>();
    public static string GetNotificationHtml(string name)
    {
        if (!_notificationHtmls.ContainsKey(name))
        {
            var path = GetNotificationPath(name);
            _notificationHtmls.Add(name, GetNotificationHtml(NotificationTemplate, File.ReadAllText(path)));
        }

        return _notificationHtmls[name];
    }

    private static string GetNotificationPath(string name)
    {
        var path = HttpContext.Current.Server.MapPath("Notifications/" + name + ".html");
        return path;
    }

    public static string GetNotificationHtml(string template, string content)
    {
        return template.Replace("[[CONTENT]]", content);
    }

    public static string _notificationTemplate;
    public static string NotificationTemplate
    {
        get
        {
            if (_notificationTemplate == null)
            {
                var path = HttpContext.Current.Server.MapPath("NotificationTemplate.html");
                _notificationTemplate = System.IO.File.ReadAllText(path);
            }

            return _notificationTemplate;
        }
    }
}