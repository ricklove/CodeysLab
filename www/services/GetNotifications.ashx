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
# FirstRun
## TITLE: Welcome to Codey's Lab
## IMAGE: http://codeyslab.com/notifications/images/codeyslablogo.png
## MESSAGE:

We hope this will provide you the best training experience ever.
Have fun and prepare to <b>Create your own Games.</b>

# Manual
## TITLE: Provide Feedback
## MESSAGE:

If you ever have a problem, please let us know with this <b>feedback</b> from.

### CHOICE: What is the problem?
- There is a Bug with this Step
- This Step is Confusing
- Something is Broken
- Other

### TEXT: Please describe the problem so we can help: What happened?


# EndOfLesson
## TITLE: Lesson Feedback
## MESSAGE:

Great job for completing the lesson!

Would you mind giving us feedback so we can improve this lesson?

### CHOICE: How difficult was this lesson (1-5)?
- Very Easy
- Easy
- Moderate
- Somewhat Hard
- Hard

### CHOICE: How helpful was this lesson for your training (1-5)?
- Completely Useless
- Not Very Helpful
- I Learned Something
- I Learned A Lot
- This was a Great Lesson!

### TEXT: What other comments would you like to share with us?


# EndOfLesson
## TITLE: Course Feedback
## MESSAGE:

Awesome! You finished the course.

We hope it was beneficial for you.

We are working on more courses, and your feedback will help us know what we should prioritize.

### CHOICE: What would be most interesting to you?
- Adding more advanced features to this course
- A course in a different genre

### TEXT: What type of game would you most like to learn how to make?

### TEXT: What features would that game include?


# 2015-05-15 11:08
## TITLE: Codey's Lab Framework Completed
## IMAGE: http://codeyslab.com/notifications/images/codeyslablogo.png
## LINK: http://codeyslab.com/2015-05-15_FrameworkCompleted
## MESSAGE:
Codey's Lab is released!
Check it out!


# 2015-05-19 10:06
## TITLE: Test
## MESSAGE:

Try this entry form.

### CHOICE: Which one is your favorite?
- Choice A
- Choice B
- Choice C
- Choice D

### TEXT: What do you think about this?

";
}