using Uno;
using Uno.IO;
using Uno.UX;
using Uno.Threading;
using Uno.Compiler.ExportTargetInterop;
using Fuse.Scripting;

namespace Fuse.AsyncIO
{
	[UXGlobalModule]
	public sealed class AsyncIOModule : NativeModule
	{
		static readonly AsyncIOModule _instance;

		public AsyncIOModule()
		{
			if(_instance != null)
				return;
			Resource.SetGlobalKey(_instance = this, "FuseJS/AsyncIO");
			AddMember(new NativePromise<BufferHandle, object>("read", Read, ConvertBufferHandle));
		}

		static object ConvertBufferHandle(Context context, BufferHandle bufferHandle)
		{
			return context.Unwrap(bufferHandle);
		}

		static Future<BufferHandle> Read(object[] args)
		{
			var path = GetPathFromArgs(args);
			var readClosure = new ReadClosure(path);
			AsyncHelpers.RunAsync(readClosure.Invoke);
			return readClosure;
		}

		class ReadClosure : Promise<BufferHandle>
		{
			string _path;

			public ReadClosure(string path) : base(UpdateManager.Dispatcher)
			{
				_path = path;
			}

			public void Invoke()
			{
				try
				{
					var bytes = File.ReadAllBytes(_path);
					Resolve(new BufferHandle(bytes));
				}
				catch(Exception e)
				{
					Reject(e);
				}
				finally
				{
					_path = null;
				}
			}
		}

		static string GetPathFromArgs(object[] args)
		{
			if (args == null)
				throw new ArgumentNullException(nameof(args));

			var filename = args.Length > 0 ? args[0] as string : null;
			if (filename == null)
			{
				throw new Scripting.Error("first argument path is required to be a string");
			}
			return filename;
		}
	}

	internal static class AsyncHelpers
	{
		class RunClosure
		{
			Action _task;

			public RunClosure(Action task)
			{
				_task = task;
			}

			public object Invoke()
			{
				_task();
				_task = null;
				return null;
			}
		}

		public static void RunAsync(Action task)
		{
			Promise<object>.Run(new RunClosure(task).Invoke);
		}
	}
}
