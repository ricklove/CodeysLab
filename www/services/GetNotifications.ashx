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

If you ever have a problem, please let us know with this <b>feedback</b> form.

### CHOICE: What is the problem?
- Something is Broken
- There is a Mistake in the Course
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


# EndOfCourse
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


# 2015-05-19 16:26
## TITLE: Community Vote: What Course do You Want?
## MESSAGE:

We at Digital Gaming Institute are helping Codey build some new courses.

And we want the community to drive the priorities.

We have chosen some old and new games based on those with the highest units sold to make our list.

So, what course do you want to see next?

### CHOICE: What type of game would you want to learn how to make?
- Action Puzzle (like Tetris)
- Voxel World Sandbox (like Minecraft)
- Physics Based Destruction (like Angry Birds)
- Tower Defense (like Plants vs Zombies)
- First Person Shooter (like Call of Duty)
- Role Playing Game (like Final Fantasy)
- Real Time Strategy (like Starcraft)
- 2D Platformer (like Super Mario Bros.)
- 3D Platformer (like Super Mario Galaxy)
- Racing (like Mario Kart)
- Fighting (like Street Fighter)

### TEXT: What option would you choose that is not listed?

";
}