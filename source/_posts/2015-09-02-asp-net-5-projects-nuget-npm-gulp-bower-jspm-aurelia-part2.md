---
layout: post
comments: true
categories: ""
published: false
title: "ASP.NET 5 Projects - NuGet-NPM-Gulp-Bower-Jspm-Aurelia-Part2"
---



## Part 2 - Adding an Aurelia App to our MVC Application

In [part 1 of this series](http://darrelltunnell.net/blog/2015/08/16/aurelia-and-asp-net-5-mvc) we created a shiny new ASP.NET 5 project.

At this point we have a very basic MVC web application.

### Replacing Bower with JSPM
I gave a simple overview of JSPM and Bower in [part 1](http://darrelltunnell.net/blog/2015/08/16/aurelia-and-asp-net-5-mvc), and for the reasons explained there, let's go ahead and ditch Bower in favour of JSPM as our javascript package manager.

#### Uninstall Bower
You will notice that your ASP.NET 5 application has a number of bower packages included by default:

![bowerpackages.PNG]({{site.baseurl}}/assets/posts/bowerpackages.PNG)

Once we uninstall Bower, we will need to add these packages back through JSPM instead, to get the application working again.

First, let's uninstall Bower. In your project is a `Bower.json` file.. delete it. (If you can't see it in Solution Explorer, you might need to 'show all files'

![bowerjson.PNG]({{site.baseurl}}/assets/posts/bowerjson.PNG)

When you install `Bower` packages, the contents of those packages are actually installed into the "lib" folder under your `wwwroot` directory. So, let's now delete this lib folder.

![wwwrootlibfolder.PNG]({{site.baseurl}}/assets/posts/wwwrootlibfolder.PNG)

After those changes, your project should look something like this:

![projectremovedbower.PNG]({{site.baseurl}}/assets/posts/projectremovedbower.PNG)

With Bower gone, what happens if we run the application now? Let's run it and find out..



1. Uninstall Bower and delete the `Bower.json` file.
2. Install JSPM (node dependency global and local?) and tell it the jspm_packages folder goes under wwwroot
3. `jspm install` all those dependencies we need.. jquery etc..
4. Find the MVC razor views and reference the scripts from the jspm packages folder instead.
5. Run the MVC application, verify it still works.

At this point we have the same MVC web application as when we started, it's just that we are now using JSPM to manage our packages instead of Bower.

### Aurelia

Now let's create an Aurelia javascript application to run on our home page.
Aurelia is a popular new javascript framework for creating SPA's. I have chosen it because I really liked Durandal, it's predessor, and I feel it's time for me to start getting more familiar with it!

todo:
1. jspm install aurelia packages.
2. add necessary javascript script includes and system js import call
3. add html and js for our first aurelia page
4. run the website in VS, make sure we see the app load up on the home page.

### Linting, Bundling, and Minification
The app works great, but it's not very optimised.. 
We are now going to set up a gulp task so that whenever we build our application in visual studio, the gulp task runs that will

1. JSHint (Lint) our javascript code to check for common errors.
2. Bundle the javascript files into 1 file.
3. Minify the javascript file.

In addition, this gulp task should also re-run whenever we save changes to any of the javascript files for our app.

Having our application just include a single bundled and minified javascript file should give it a nice performance boost.

TODO:

### Browser Refresh
Isn't it annoying though that whenever we make a change to our javascript file, or some HTML for our application, we have to refresh the browser to see our changes!

Well with Browser-Sync that is a thing of the past.

TODO: Explain how to set up browser-sync, gulp task etc, and sepcify port number in gulp task options, and proxy.. Then change project website settings to launch default url of the proxy when we start the project. Then all we have to do is serve which starts browser sync, and gets gulp watching for changes, then with gulp serve running we can run the website and debug in VS as normal whever we need to.
