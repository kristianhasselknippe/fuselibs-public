using Uno;
using Uno.IO;
using Uno.Time;
using Uno.UX;
using Uno.Threading;
using Uno.Collections;
using Fuse.Scripting;

namespace Fuse.AsyncIO
{
	public class BufferHandle
	{
		static BufferHandle()
		{
			ScriptClass.Register(typeof(BufferHandle),
				new ScriptMethod<BufferHandle>("release", release, ExecutionThread.MainThread));
		}

		public byte[] Buffer { get; private set; }

		internal BufferHandle(byte[] buffer)
		{
			Buffer = buffer;
		}

		public void Release()
		{
			Buffer = null;
		}

		static void release(Context context, BufferHandle bufferHandle, object[] args)
		{
			bufferHandle.Release();
		}
	}
}
