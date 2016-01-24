---
layout: post
comments: true
categories: ""
published: false
title: "ASP.NET 5 Projects - NuGet-NPM-Gulp-Bower-Jspm-Aurelia-Part2"
---



## Part 2 - Replacing Bower with JSPM

In [part 1 of this series](http://darrelltunnell.net/blog/2015/08/16/aurelia-and-asp-net-5-mvc) we created a shiny new ASP.NET 5 project.

At this point we have a very basic, default, MVC web application.

For reasons discussed in [part 1](http://darrelltunnell.net/blog/2015/08/16/aurelia-and-asp-net-5-mvc), let's now go ahead and ditch Bower in favour of JSPM as our javascript package manager.

#### Uninstall Bower
You will notice that your ASP.NET 5 application has a number of bower packages included by default:

![bowerpackages.PNG]({{site.baseurl}}/assets/posts/bowerpackages.PNG)

First, let's uninstall Bower. In your project is a `Bower.json` file. Delete it! (If you can't see it in Solution Explorer, you might need to 'show all files'

![bowerjson.PNG]({{site.baseurl}}/assets/posts/bowerjson.PNG)

When you install `Bower` packages, they are installed under the "lib" folder within your `wwwroot` directory. So, let's now delete this lib folder which will delete all of these packages.

![wwwrootlibfolder.PNG]({{site.baseurl}}/assets/posts/wwwrootlibfolder.PNG)

After those changes, your project should look something like this:

![projectremovedbower.PNG]({{site.baseurl}}/assets/posts/projectremovedbower.PNG)

With Bower gone and those javascript / css packages deleted, what happens if we run the application now? Let's run it and find out..

![runappbowerremoved.PNG]({{site.baseurl}}/source/assets/posts/runappbowerremoved.PNG)

As you can see, there are now errors displayed in the browser, and our site looks awful. This makes sense - our application is referencing javascript and css files that used to live in the lib folder, and now they are no longer found because we deleted them. 

To fix this situation we'll need to add these packages back to our application, using `JSPM`, and then fix up the way our application is `loading` these dependencies (javascript, css files) at runtime. 

#### Installing JSPM

JSPM can be installed as a local `NPM` package.

1. Open `Package.json`
2. Add `JSPM` and whatever the latest version is:

![addjspmnodejspackage.PNG]({{site.baseurl}}/assets/posts/addjspmnodejspackage.PNG)

3. Save the file. 

The `NPM` package for `JSPM` should now be downloaded and installed into your project. You will see that the package is installed into the "node_modules" folder within your project.

![nodemodulesfolderjspm.PNG]({{site.baseurl}}/assets/posts/nodemodulesfolderjspm.PNG)

#### Configuring JSPM

Now that the `JSPM` package has been installed, we need to configure `JSPM`.
The way to do this, is a little bit fiddely, as you have to drop to the command line - there is no fancy support for `JSPM` in Visual Studio at the moment like there is for `Bower`. 

1. Open a `command prompt` window, and `CD` to your project directory
2. Type `jspm init` and hit enter.

![commandlinejspminit.PNG]({{site.baseurl}}/assets/posts/commandlinejspminit.PNG)

You will now be asked a series of questions. At the end of answering these questions, the relevent `config` will be produced within the project.

Here are the answers. Some of them you can just hit enter without typing anything, and the default value will be used.

![jspminit.PNG]({{site.baseurl}}/assets/posts/jspminit.PNG)

I'll quickly run through each option briefly.. But you should defer to the `JSPM` documentation site for further clarifications.

1. "Would you like jspm to prefix the jspm package.json properties under jspm?"
We answer yes to this (the default) and this just means that JSPM will store its project configuration within a "jspm" section in our existing `package.json` file.

2. "Enter server baseURL (public folder path)"
The word URL is a bit confusing here. This is the relative path to your "public" folder within the project. By public folder, we mean the folder that will serve up static files and is therefore accessible to a browser. We need to set this to the path to our `wwwroot` directory. So the value we set for this question is `./wwwroot` as the value is relative to the current (project) directory.

3. "Enter jspm packages folder [wwwroot\jspm_packages]"
We accept the default value for this question. Previously, our Bower packages were installed under `wwwroot\lib` folder, so if you want to keep this consistent you could change this value to `wwwroot\lib`. I however am happy to keep the default.

4. "Enter config file path [wwwroot\config.js]"
This is the path to where you would like the config javascript file to be placed. Remember, `JSPM` is not just a package manager in a the sense of allowing you to adopt packages at `design time`. It also has features that are used your application when it runs. This means it has a `config` file (a javascript file) that your application will actually need to reference at runtime. This config file must therefore be placed in a directory that can be served up. We accept the default value (wwwroot\config.js)  

5. "Configuration file wwwroot\config.js doesn't exist, create it?" [yes]
We accept the default which is `yes` as we want it to create this config file for us.

6. "Enter client baseURL (public folder URL) [/]
This is the URL or path that the browser uses to browse to the public folder (wwwroot). We accept the default value, because our public folder (wwwroot) is served up as the root path ("/").

7. "Do you wish to use a transpiler? [yes]"
We accept the default answer of "yes" because transpilers are awesome. They allow us to write javascript using the latest language specifications, and then they "transpile" that javascript so that it can run in browsers that don't support the latest language specifications yet.

8. "Which ES6 transpiler would you like to use, Babel, Typescript, or Traceur? [babel]"
For the purposes of this blog, I am accepting the default of "Babel". 

The transpiler will just allow us to write javascript using ES6 language features, and this will be transpiled to run in browsers that don't support ES6 yet.

#### Installing JSPM Packages

Now that we have `JSPM` configured, it's time to install those packages that we previously had installed via `Bower`.

Back in the `command prompt` run the following commands:

1. `jspm install jquery`
2. `jspm install jquery-validation`
3. `jspm install github:aspnet/jquery-validation-unobtrusive`
2. `jspm install bootstrap`

Once that is done, those packages will now be installed under your `wwwroot\jspm_packages` folder:

![jspmpackages.PNG]({{site.baseurl}}/assets/posts/jspmpackages.PNG)

The next step is to fix up our MVC application so that loads our javascript and css using the `jspm` module loader.




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
