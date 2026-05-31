using System;
using Avalonia;
using Avalonia.Controls.ApplicationLifetimes;
using ReactiveUI;
using ReactiveUI.Avalonia;
using Wabbajack.Paths;

namespace Portramatic
{
    // Para publicar:
    // Windows:  dotnet publish -r win-x64 -c Release -p:PublishReadyToRun=true --self-contained -p:PublishSingleFile=true -p:DebugType=embedded
    // macOS:    dotnet publish -r osx-arm64 -c Release -p:PublishReadyToRun=true --self-contained -p:PublishSingleFile=true -p:DebugType=embedded
    //          (use osx-x64 para Macs Intel)
    class Program
    {
        public static void Main(string[] args)
        {
            if (args.Length == 1)
            {
                Program.AdminPath = args[0].ToAbsolutePath();
            }
            BuildAvaloniaApp()
                .StartWithClassicDesktopLifetime(args);
        }

        public static AbsolutePath AdminPath { get; set; }
        public static bool IsAdminMode => AdminPath != default;

        // Avalonia configuration, don't remove; also used by visual designer.
        public static AppBuilder BuildAvaloniaApp()
            => AppBuilder.Configure<App>()
                .UsePlatformDetect()
                .LogToTrace()
                .UseReactiveUI(builder => { });
    }
}
