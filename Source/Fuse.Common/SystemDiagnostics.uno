using Uno;
using Uno.Compiler;
using Uno.Collections;

namespace Fuse
{
	internal class FrameArgs
	{
		public readonly int FrameIndex;
		public readonly double FrameTime;

		public FrameArgs(
			int frameIndex,
			double frameTime)
		{
			FrameIndex = frameIndex;
			FrameTime = frameTime;
		}

		public override string ToString()
		{
			return "FrameIndex: " + FrameIndex + ", FrameTime: " + (FrameTime * 1000.0) + " ms";
		}
	}

	internal class UpdateArgs
	{
		public readonly double UpdateTime;

		public UpdateArgs(double updateTime)
		{
			UpdateTime = updateTime;
		}
	}

	internal delegate void SystemDiagnosticHandler<TArg>(TArg arg);

	internal static class SystemDiagnostics
	{
		public static event SystemDiagnosticHandler<FrameArgs> FrameDiagnostic;
		public static event SystemDiagnosticHandler<UpdateArgs> UpdateDiagnostic;

		static int _frameIndex = -1;
		static double _drawStart = 0.0;
		public static void BeginDraw()
		{
			_frameIndex = UpdateManager.FrameIndex;
			_drawStart = Uno.Diagnostics.Clock.GetSeconds();
		}

		public static void EndDraw()
		{
			var drawEnd = Uno.Diagnostics.Clock.GetSeconds();
			var elapsed = drawEnd - _drawStart;
			var fd = FrameDiagnostic;
			if (fd != null)
				fd(new FrameArgs(_frameIndex, elapsed));
		}

		static double _updateStart = 0.0;
		public static void BeginUpdate()
		{
			_updateStart = Uno.Diagnostics.Clock.GetSeconds();
		}

		public static void EndUpdate()
		{
			var updateEnd = Uno.Diagnostics.Clock.GetSeconds();
			var elapsed = updateEnd - _updateStart;
			var ud = UpdateDiagnostic;
			if (ud != null)
				ud(new UpdateArgs(elapsed));
		}
	}
}
