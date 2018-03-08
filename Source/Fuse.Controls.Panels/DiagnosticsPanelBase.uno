using Uno;
using Uno.UX;
using Uno.Collections;
using Fuse;
using Fuse.Layouts;
using Fuse.Elements;

namespace Fuse.Controls
{
	public class DiagnosticsPanelBase : Panel, Node.ISubtreeDataProvider, IObject
	{
		ContextDataResult ISubtreeDataProvider.TryGetDataProvider(Node child, DataType type, out object provider) { provider = this; return ContextDataResult.Stop; }

		bool IObject.ContainsKey(string key) { return _properties.ContainsKey(key); }

		object IObject.this[string key] { get { return _properties[key]; } }

		string[] IObject.Keys { get { return _properties.Keys.ToArray(); } }

		protected override void OnRooted()
		{
			base.OnRooted();
			SystemDiagnostics.FrameDiagnostic += OnFrameDiagnostic;
		}

		protected override void OnUnrooted()
		{
			base.OnUnrooted();
			SystemDiagnostics.FrameDiagnostic -= OnFrameDiagnostic;
		}

		Dictionary<string,object> _properties = new Dictionary<string,object>();

		public DiagnosticsPanelBase()
		{
			_properties.Add(FramesPerSecond, 0);
			_properties.Add(FrameIndex, 0);
		}

		const string FramesPerSecond = "frames_per_second";
		const string FrameIndex = "frame_index";

		int CurrentFramesPerSecond
		{
			set { _properties[FramesPerSecond] = value; }
		}

		int CurrentFrameIndex
		{
			set { _properties[FrameIndex] = value; }
		}

		List<double> _frames = new List<double>();
		int _previousFrame = -1;

		void OnFrameDiagnostic(FrameArgs args)
		{
			if (_previousFrame != (args.FrameIndex - 1))
				_frames.Clear();

			if (_frames.Count >= 60)
				_frames.RemoveAt(0);

			_previousFrame = args.FrameIndex;
			CurrentFrameIndex = args.FrameIndex;

			var frameTime = Math.Max(args.FrameTime, 1.0 / 60.0);

			_frames.Add(frameTime);

			var sum = 0.0;
			for (var i = 0; i < _frames.Count; i++)
				sum += _frames[i];

			CurrentFramesPerSecond = (int)(1.0 / (sum / _frames.Count));
			BroadcastDataChange(null, this);
		}
	}
}
