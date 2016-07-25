---
layout: post
comments: true
published: true
title: ASPNET Core TagHelper's - A Better @addTagHelper type resolver
---
## The problem

This is about TagHelper's in ASP.NET Core, and my experience with them and a modular application.

Suppose your application loads some assemblies dynamically - for example, from a plugins folder, and those assemblies contain `TagHelper`'s.

In startup.cs you would have something like this to register your assemblies with the MVC parts system:

```csharp

var assy = Assembly.LoadFile("C:\\SomePath\Plugin.Authentication.dll");
mvcBuilder.AddApplicationPart(assy);

var assy = Assembly.LoadFile("C:\\SomePath\Plugin.Markdown.Assembly.dll");
mvcBuilder.AddApplicationPart(assy);


```

Now suppose your have a Razor View that has some markup that can be targeted by those tag helpers:

```

 <plugin-authentication />
 <plugin-markdown visible="true"/>

```

The problem is that if you add the addTagHelper directive to `_ViewImports.cshtml` and start your application running, you'll see an error immediately on startup:

```
@addTagHelper "*, Plugin.Markdown.Assembly*"
```

This is because by defualt MVC does not resolve `TagHelper` assemblies registered with the parts system (atleast this is true as of RTM 1.0.0) so it complains when it processes that directive, saying it can't find such an assembly - because it can only see assemblies that are in the bin folder by default (it uses `Assembly.Load` to load the assembly with the name specified in the directive.


To workaround this you need to add this line in your `startup.cs`

```csharp

mvcBuilder.AddTagHelpersAsServices();

```

That line registers some replacement services that will check the application parts system when trying to resolve the tag helper assembly based on the name provided by the directive.

# So what else?

Well this works but it's still not very flexible, because in order for plugins to work on your razor page, you have to kee adding a new directive for each plugin that you want to function, like this:

```
@addTagHelper "*, Plugin.Markdown.Assembly*"
@addTagHelper "*, Plugin.Authentication*"
```

So now imagine that your application is deployed, and someone creates a new plugin. They drop the plugin in the plugins folder, and restart your application. Your application loads up the plugin assembly on startup and registers it with application parts system. The plugin contains a `TagHelper` that targets a particular element on every page of the application. Does the TagHelper just automatically kick in? ofcourse not.


# But I want it too automatically kick in..

Yup. So here is my solution to this plugin, and that is to allow `globbing` to be supported in the `addTagHelper` directiv for the assembly name, just like it is for the TypeName.

So this is how you do that.

# ITagHelperTypeResolver


We need to create an `ITagHelperTypeResolver` and implement it's `Resolve` method. This method takes the string provided by in the `addTagHelper` directive and returns all `TagHelper` type's that are matches to that string. We will make our implementation support globbing on the assembly name so it can match `TagHelper` types accross multiple assemblies instead of just one. We'll also make sure to use the `Application Parts` system to find our assemblies so we include those plugins registered at runtime.


Here is my implementation:

```csharp 

public class AssemblyNameGlobbingTagHelperTypeResolver : ITagHelperTypeResolver
    {
       
        private static readonly System.Reflection.TypeInfo ITagHelperTypeInfo = typeof(ITagHelper).GetTypeInfo();

        protected TagHelperFeature Feature { get; }

        public AssemblyNameGlobbingTagHelperTypeResolver(ApplicationPartManager manager)
        {
            if (manager == null)
            {
                throw new ArgumentNullException(nameof(manager));
            }

            Feature = new TagHelperFeature();
            manager.PopulateFeature(Feature);

            // _manager = manager;

        }

        /// <inheritdoc />
        public IEnumerable<Type> Resolve(
            string name,
            SourceLocation documentLocation,
            ErrorSink errorSink)
        {
            if (errorSink == null)
            {
                throw new ArgumentNullException(nameof(errorSink));
            }

            if (string.IsNullOrEmpty(name))
            {
                var errorLength = name == null ? 1 : Math.Max(name.Length, 1);
                errorSink.OnError(
                    documentLocation,
                    "Tag Helper Assembly Name Cannot Be Empty Or Null",
                    errorLength);

                return Type.EmptyTypes;
            }


            IEnumerable<TypeInfo> libraryTypes;
            try
            {
                libraryTypes = GetExportedTypes(name);
            }
            catch (Exception ex)
            {
                errorSink.OnError(
                    documentLocation,
                    $"Cannot Resolve Tag Helper Assembly: {name}, {ex.Message}",
                    name.Length);

                return Type.EmptyTypes;
            }

            return libraryTypes;

        }


        /// <inheritdoc />
        protected IEnumerable<System.Reflection.TypeInfo> GetExportedTypes(string assemblyNamePattern)
        {
            if (assemblyNamePattern == null)
            {
                throw new ArgumentNullException(nameof(assemblyNamePattern));
            }

            var results = new List<System.Reflection.TypeInfo>();

            for (var i = 0; i < Feature.TagHelpers.Count; i++)
            {
                var tagHelperAssemblyName = Feature.TagHelpers[i].Assembly.GetName();

                if (assemblyNamePattern.Contains("*")) // is it actually a pattern?
                {
                    if (tagHelperAssemblyName.Name.Like(assemblyNamePattern))
                    {
                        results.Add(Feature.TagHelpers[i]);
                        continue;
                    }
                }

                // not a pattern so treat as normal assembly name.
                var assyName = new AssemblyName(assemblyNamePattern);
                if (AssemblyNameComparer.OrdinalIgnoreCase.Equals(tagHelperAssemblyName, assyName))
                {
                    results.Add(Feature.TagHelpers[i]);
                    continue;
                }
            }

            return results;
        }

        private class AssemblyNameComparer : IEqualityComparer<AssemblyName>
        {
            public static readonly IEqualityComparer<AssemblyName> OrdinalIgnoreCase = new AssemblyNameComparer();

            private AssemblyNameComparer()
            {
            }

            public bool Equals(AssemblyName x, AssemblyName y)
            {
                // Ignore case because that's what Assembly.Load does.
                return string.Equals(x.Name, y.Name, StringComparison.OrdinalIgnoreCase) &&
                       string.Equals(x.CultureName ?? string.Empty, y.CultureName ?? string.Empty, StringComparison.Ordinal);
            }

            public int GetHashCode(AssemblyName obj)
            {
                var hashCode = 0;
                if (obj.Name != null)
                {
                    hashCode ^= obj.Name.GetHashCode();
                }

                hashCode ^= (obj.CultureName ?? string.Empty).GetHashCode();
                return hashCode;
            }
        }


    }


```

Now we just register that on startup:

```

  services.AddSingleton<ITagHelperTypeResolver, AssemblyNameGlobbingTagHelperTypeResolver>();

```

And finally, in any view (or _ViewImports.cshtml_) where we want to autoamtically include TagHelpers from plugin assemblies:


```
@addTagHelper "*, Plugin.*"

```

You are welcome.








