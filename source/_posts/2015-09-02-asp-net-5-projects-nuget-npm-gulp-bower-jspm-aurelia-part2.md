---
layout: post
comments: true
categories: "ASP.NET,Aurelia,Gulp,Bower,JSPM"
published: true
title: "ASP.NET 5 Projects - NuGet-NPM-Gulp-Bower-Jspm-Aurelia-Part2"
---



## Part 2 - Replacing Bower with JSPM

In [part 1 of this series](http://darrelltunnell.net/blog/2015/08/16/aurelia-and-asp-net-5-mvc) we created a shiny new ASP.NET 5 project.

At this point we have a very basic, default, MVC web application.

For reasons discussed in [part 1](http://darrelltunnell.net/blog/2015/08/16/aurelia-and-asp-net-5-mvc), let's now go ahead and ditch Bower in favour of JSPM as our javascript package manager.

### Uninstall Bower
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

### Install JSPM

JSPM can be installed as a local `NPM` package.

1. Open `Package.json`
2. Add `JSPM` and whatever the latest version is:

![addjspmnodejspackage.PNG]({{site.baseurl}}/assets/posts/addjspmnodejspackage.PNG)

3. Save the file. 

The `NPM` package for `JSPM` should now be downloaded and installed into your project. You will see that the package is installed into the "node_modules" folder within your project.

![nodemodulesfolderjspm.PNG]({{site.baseurl}}/assets/posts/nodemodulesfolderjspm.PNG)

### Configure JSPM

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

### Installing JSPM Packages

Now that we have `JSPM` configured, it's time to install those packages that we previously had installed via `Bower`.

Back in the `command prompt` run the following commands:

1. `jspm install jquery`
2. `jspm install jquery-validation`
3. `jspm install github:aspnet/jquery-validation-unobtrusive`
2. `jspm install bootstrap`

Once that is done, those packages will now be installed under your `wwwroot\jspm_packages` folder:

![jspmpackages.PNG]({{site.baseurl}}/assets/posts/jspmpackages.PNG)

The next step is to fix up our MVC application so that it loads our javascript and css using the `module loader`.

### Transitioning to Modules.

The changes we have been making up until now, have been about managing our packages in our project at design time. This next step is about making changes to our application so that rather than including javascript and css files directly into particular pages, we instead, write modular javascript, that declares any dependencies it has, and then allow the `SystemJS` module loader to satisfy those dependencies for us at runtime by loading any needed javascript / css.

First, we need to include the module loader, and it's configuration file, into our application.

If you open `_Layout.cshtml` you will see a section like this:

```xml
 <environment names="Development">
            <script src="~/lib/jquery/dist/jquery.js"></script>
            <script src="~/lib/bootstrap/dist/js/bootstrap.js"></script>
            <script src="~/js/site.js" asp-append-version="true"></script>
        </environment>
        <environment names="Staging,Production">
            <script src="https://ajax.aspnetcdn.com/ajax/jquery/jquery-2.1.4.min.js"
                    asp-fallback-src="~/lib/jquery/dist/jquery.min.js"
                    asp-fallback-test="window.jQuery">
            </script>
            <script src="https://ajax.aspnetcdn.com/ajax/bootstrap/3.3.5/bootstrap.min.js"
                    asp-fallback-src="~/lib/bootstrap/dist/js/bootstrap.min.js"
                    asp-fallback-test="window.jQuery && window.jQuery.fn && window.jQuery.fn.modal">
            </script>
            <script src="~/js/site.min.js" asp-append-version="true"></script>
        </environment>
```

Let's comment out that whole section and replace it with this:


```xml

<script src="~/jspm_packages/system.js"></script>
<script src="~/config.js"></script>
<script>System.import("js/site");</script>

```

At this point, let's run the application!

You should now be able to see that we no longer get any errors about failing to load  javascript files `jquery.js` and `bootstrap.js`. In fact, **those javascript files are not being loaded anymore.**

![jspmmissingcss.PNG]({{site.baseurl}}/assets/posts/jspmmissingcss.PNG)

Why is that? Well it's because we no longer directly include the `bootstrap` and `jquery` scripts into our `_Layout.cshtml` file, so they aren't being loaded! So we aren't getting 404's anymore.

This is the nature of `modular` javascript. What we have transitioned to now, is a Modular concept, where `bootstrap` and `jquery` are modules that will only be loaded, if we load a module that requires them as dependencies.

With that in mind, the module we are currently loading is one called `js/site`

```xml
<script>System.import("js/site");</script>
```

This resolves to the `js/site.js` file in our `wwwroot` directory. This file is currently empty, meaning there are no dependencies declared in there to any other modules, and this, there is nothing else that the module loader needs to load, and that's why it doesn't bother loading `JQuery` or `Bootstrap` anymore.

This is good, because in our application, we might have some simple pages that don't require `JQuery` to be loaded. We might have other pages that use all sorts of javascript libraries and fancy plugins. Therefore, in our `_Layout.cshtml` file, we will keep our dependencies as few as possible, and ensure that only dependencies that we require on **every page** will be included. 

Let's now assume that we are willing to load `JQuery`, and `Bootstrap` as a dependency for every page:

1. Open `site.js` and insert the following code, then save it an re-run your application:

```javascript
import $ from 'jquery';
import bootstrap from 'bootstrap';
```

This is `ES6` syntax for declaring a dependency on a module.

You should now see that `JQuery` and `Bootstrap` are loaded:

![jspmjqueryandbootstrapdependency.PNG]({{site.baseurl}}/assets/posts/jspmjqueryandbootstrapdependency.PNG)

### What about CSS

Now that we have got our javascript files loading again, we are still left with 404's for the bootstrap.css file.

Well we can use JSPM for CSS too, but we need to install the `CSS` plugin.

#### Installing the CSS plugin for JSPM

Back in the `command prompt` in your project directory, run the following

```
jspm install css
```

Now go back to your `site.js` file, and add an import for the bootstrap.css. It should now look like this:

```
import $ from 'jquery';
import bootstrap from 'bootstrap';
import 'bootstrap/css/bootstrap.css!'
```

Lastly, in `_Layout.cshtml`, comment out the link to the bootstrap.css file that doesn't exist.

```xml

 <environment names="Development">
        @*<link rel="stylesheet" href="~/lib/bootstrap/dist/css/bootstrap.css" />*@
        <link rel="stylesheet" href="~/css/site.css" />
    </environment>
    <environment names="Staging,Production">
        @*<link rel="stylesheet" href="https://ajax.aspnetcdn.com/ajax/bootstrap/3.3.5/css/bootstrap.min.css"
            asp-fallback-href="~/lib/bootstrap/dist/css/bootstrap.min.css"*@
        asp-fallback-test-class="sr-only" asp-fallback-test-property="position" asp-fallback-test-value="absolute" />
        <link rel="stylesheet" href="~/css/site.min.css" asp-append-version="true" />
    </environment>

```

Now run your application!

![jspmnoerrors.PNG]({{site.baseurl}}/source/assets/posts/jspmnoerrors.PNG)

Wahoo! We now have no errors in the console window, our javascript and css is being loaded - and our application looks ok again.

#### Flash of unstyled content

You may notice that using the CSS plugin, your page is displayed in an unstyled form for a brief moment, whilst the CSS file is loaded asynchronosuly. This is known as a [Flash of Unstyled Content](http://www.techrepublic.com/blog/web-designer/how-to-prevent-flash-of-unstyled-content-on-your-websites/) and is a problem with using the CSS plugin at present - [see here](https://github.com/systemjs/plugin-css/issues/57). Hopefully this will be addressed in the future, but in the meantime, feel free not to use the CSS Plugin if this is an issue, you can instead just directly reference the `Bootstrap.css` file in the `_Layout.cshtml` file as before, but from its new location under the `jspm_packages` directory.

### Finishing Touches - `_ValidationScripsPartial.cshtml`

Our application is running again, but you may notice a few of the pages have errors.

If you click on "Register" link for example you will see these errors in the browser console window:

![jspmregisterpageproblems.PNG]({{site.baseurl}}/source/assets/posts/jspmregisterpageproblems.PNG)

This is because many of the views within our MVC application are rendering a partial called `_ValidationScriptsPartial.cshtml`

For example, if you look at the bottom of `Register.cshtml`, you will see the following:

```csharp

@section Scripts {
    @{ await Html.RenderPartialAsync("_ValidationScriptsPartial"); }
}

```

If you look at the contents of `_ValidationScriptsPartial` we can see that it is actually including additional scripts onto the page:

```
<environment names="Development">
    <script src="~/lib/jquery-validation/dist/jquery.validate.js"></script>
    <script src="~/lib/jquery-validation-unobtrusive/jquery.validate.unobtrusive.js"></script>
</environment>
<environment names="Staging,Production">
    <script src="https://ajax.aspnetcdn.com/ajax/jquery.validate/1.14.0/jquery.validate.min.js"
            asp-fallback-src="~/lib/jquery-validation/dist/jquery.validate.min.js"
            asp-fallback-test="window.jQuery && window.jQuery.validator">
    </script>
    <script src="https://ajax.aspnetcdn.com/ajax/mvc/5.2.3/jquery.validate.unobtrusive.min.js"
            asp-fallback-src="~/lib/jquery-validation-unobtrusive/jquery.validate.unobtrusive.min.js"
            asp-fallback-test="window.jQuery && window.jQuery.validator && window.jQuery.validator.unobtrusive">
    </script>
</environment>

```

As you can see, depending upon the environment that ASP.NET determines your application is running on, this renders some script includes to particular js files, used for forms validation. These were previoulsy located within `Bower` packages, that we have deleted.

To correct this, we'll just need to instruct the module loader to load the `jquery.validate.unobtrusive` module instead. Notice that you don't need to also instruc the module loader to load the `jquery.validate` module, because `jquery.validate` is a dependency of `jquery.validate.unobtrusive` so the module loader will resolve it automatically.  

So change the contents of `_ValidationScriptsPartial.cshtml` to this:

```
<script>System.import("aspnet/jquery-validation-unobtrusive");</script>
```

And now - everything is working!

![jspmallworking.PNG]({{site.baseurl}}/source/assets/posts/jspmallworking.PNG)

## Recap

In this blog post, we have replaced `Bower` with `JSPM` and changed the way our application loads it's javascript and css, so that it now uses a module loader.

We also saw that modular CSS currently has a flash of unstyled content issue, and so if that's an issue for your application then it's probably best to stick to directly linking to your css files as before, rather than trying to load them through the module loader. That's a decision for you to make!

In the next blog post/s in this series, I will attempt to cover:

1. Creating a basic Aurelia application on the Home page.
2. Introducing Linting, Bundling, and Minification.
3. Automatic Browser Refresh as we make changes.

I hope this has helped you, and apologies if the article seems rushed in places... It was! :)

As always, appreciate any feedback below!