using Uno;
using Uno.UX;
using Fuse.Platform;
using Fuse.Scripting;

namespace FuseUIEvents
{
	public class UIEventArgs
	{
		public string Visual { get; private set; }

		public UIEventArgs(string v)
		{
			Visual = v;

		}
	}

	public class UIPointerEventArgs : UIEventArgs
	{
		public float2 PointerPosLocal { get; private set; }
		public float2 PointerPosWorld { get; private set; }
		
		public UIPointerEventArgs(string visual, float2 ppl, float2 ppw): base(visual)
		{
			PointerPosLocal = ppl;
			PointerPosWorld = ppw;
		}
	}

	public enum UIFocusEventType
	{
		Gained,
		Lost
	}

	public class UIFocusEventArgs : UIEventArgs
	{
		public UIFocusEventType EventType { get; private set; }
		public UIFocusEventArgs(string v, UIFocusEventType type) : base(v)
		{
			EventType = type;
		}
	}
	
	[UXGlobalModule]
	public sealed class UIEvents : NativeEventEmitterModule
	{
		static UIEvents _instance;
		
		public UIEvents()
			: base(true,
				   "gotUIEvent")
		{
			debug_log("Initialized UIEvents");
			if(_instance != null)
				return;
			Resource.SetGlobalKey(_instance = this, "FuseJS/UIEvents");
			var onGotUIEvent = new NativeEvent("onGotUIEvent");

			On("gotUIEvent", onGotUIEvent);
			AddMember(onGotUIEvent);
		}

		public static void EmitUIEvent(UIEventArgs arg)
		{
			debug_log("Got Visual Event: " + arg);
			if (_instance == null)
			{
				debug_log("UIEvent instance was null");
				return;
			}
			_instance.OnGotUIEvent(arg);
		}

		void OnGotUIEvent(UIEventArgs arg)
		{
			EmitFactory(GotUIEventArgsFactory, arg);
		}

		static object[] GotUIEventArgsFactory(Context context, UIEventArgs args)
		{
			return new object[] { "gotUIEvent", Converter(context, args) };
		}

		static Fuse.Scripting.Object Converter(Context context, UIEventArgs args)
		{
			var obj = context.NewObject();
			if(args != null)
			{
				obj["visual"] = args.Visual;

				if (args is UIPointerEventArgs)
				{
					var pargs = (UIPointerEventArgs)args;
					var a1 = context.NewObject();
					a1["x"] = pargs.PointerPosLocal.X;
					a1["y"] = pargs.PointerPosLocal.Y;
					
					var a2 = context.NewObject();
					a2["x"] = pargs.PointerPosWorld.X;
					a2["y"] = pargs.PointerPosWorld.Y;

					obj["pointerPosLocal"] = a1;
					obj["pointerPosWorld"] = a2;

					obj["type"] = "pointer_event";
				}
				else if (args is UIFocusEventArgs)
				{
					var fargs = (UIFocusEventArgs)args;
					obj["type"] = "focus_event";
					if (fargs.EventType == UIFocusEventType.Gained)
						obj["focus_event_type"] = "gained";
					else
						obj["focus_event_type"] = "lost";
				}
			}
			return obj;
		}
	}
}
