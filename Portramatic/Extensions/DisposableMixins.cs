using System;
using System.Reactive.Disposables;

namespace Portramatic.Extensions
{
    /// <summary>
    /// Provides the DisposeWith extension method.
    /// Workaround for System.Reactive 6.1.0 compatibility issue with .NET 10.
    /// </summary>
    public static class DisposableMixins
    {
        /// <summary>
        /// Adds the disposable to the CompositeDisposable and returns the disposable.
        /// </summary>
        public static T DisposeWith<T>(this T disposable, CompositeDisposable compositeDisposable) where T : IDisposable
        {
            if (compositeDisposable is null) throw new ArgumentNullException(nameof(compositeDisposable));
            compositeDisposable.Add(disposable);
            return disposable;
        }
    }
}
