using Uno;
using Uno.UX;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Fuse.Controls.Native;
using Fuse.Controls.Internal;

namespace Fuse.Controls.Native.iOS
{
	extern(iOS) internal class NativeCanvas : ICanvas
	{
		public IntPtr BitmapContext { get { return _bitmapContext; } }
		public int2 PixelSize { get { return _pixelSize; } }

		IntPtr _bitmapContext;
		int2 _pixelSize;
		float _pixelsPerPoint;

		public NativeCanvas(float2 size, float pixelsPerPoint)
		{
			_pixelSize = (int2)Math.Ceil(size * pixelsPerPoint);
			_pixelsPerPoint = pixelsPerPoint;
			_bitmapContext = NewBitmapContext(_pixelSize.X, _pixelSize.Y);
		}

		public NativeCanvas(int2 pixelSize) : this((float2)pixelSize, 1.0f) { }

		public void Clear(float4 color)
		{
			_bitmapContext.Clear(_pixelSize, color);
		}

		public void Draw(Line line)
		{
			_bitmapContext.Draw(line.Scale(_pixelsPerPoint));
		}

		public void Draw(IList<Line> lines)
		{
			ICanvas canvas = (ICanvas)this;
			foreach (var line in lines)
				canvas.Draw(line);
		}

		public void Draw(Internal.Circle circle)
		{
			_bitmapContext.Draw(circle.Scale(_pixelsPerPoint));
		}

		public void Draw(IList<Internal.Circle> circles)
		{
			ICanvas canvas = (ICanvas)this;
			foreach (var circle in circles)
				canvas.Draw(circle);
		}

		public void Draw(Stroke stroke)
		{
			Draw(stroke.Lines);
			Draw(stroke.Circles);
		}

		public void Draw(Bitmap bitmap, Rect rect)
		{
			_bitmapContext.Draw(bitmap, rect);
		}

		public void PushTransform(float3x3 transform)
		{
			_bitmapContext.PushTransform(transform);
		}

		public void PopTransform()
		{
			_bitmapContext.PopTransform();
		}

		public void Dispose()
		{
			_bitmapContext.Release();
			_bitmapContext = IntPtr.Zero;
		}

		public Bitmap AsBitmap()
		{
			return new Bitmap(MakeBitmap(_bitmapContext));
		}

		[Foreign(Language.ObjC)]
		static IntPtr MakeBitmap(IntPtr bitmapContext)
		@{
			return CGBitmapContextCreateImage((CGContextRef)bitmapContext);
		@}

		[Foreign(Language.ObjC)]
		static IntPtr NewBitmapContext(int width, int height)
		@{
			CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
			CGContextRef context = CGBitmapContextCreate(
				NULL,
				width,
				height,
				8,
				4 * width,
				colorSpace,
				kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
			CGColorSpaceRelease(colorSpace);
			CGContextClearRect(context, { { 0.0f, 0.0f, }, { (CGFloat)width, (CGFloat)height } });
			return context;
		@}
	}

	extern(iOS) static class CGContextExtensions
	{
		[Foreign(Language.ObjC)]
		public static void Release(this IntPtr ctx)
		@{
			CGContextRelease((CGContextRef)ctx);
		@}

		public static void Draw(this IntPtr ctx, Line line)
		{
			var from = line.From;
			var to = line.To;
			SetColor(ctx, line.Color);
			DrawLine(
				ctx,
				from.X,
				from.Y,
				to.X,
				to.Y,
				line.Width);
		}

		public static void Draw(this IntPtr ctx, Bitmap bitmap, Rect rect)
		{
			var pos = rect.Position;
			var size = rect.Size;
			DrawBitmap(ctx, bitmap.Handle, pos.X, pos.Y, size.X, size.Y);
		}

		public static void PushTransform(this IntPtr ctx, float3x3 transform)
		{
			ctx.SaveGState();
			Transform(ctx,
				transform.M11, transform.M12,
				transform.M21, transform.M22,
				transform.M31, transform.M32);
		}

		public static void PopTransform(this IntPtr ctx)
		{
			ctx.RestoreGState();
		}

		[Foreign(Language.ObjC)]
		static void DrawLine(
			IntPtr ctx,
			float fromX,
			float fromY,
			float toX,
			float toY,
			float width)
		@{
			CGContextRef c = (CGContextRef)ctx;
			CGContextSetLineCap(c, kCGLineCapRound);
			CGContextSetLineWidth(c, width);
			CGContextMoveToPoint(c, fromX, fromY);
			CGContextAddLineToPoint(c, toX, toY);
			CGContextStrokePath(c);
		@}

		[Foreign(Language.ObjC)]
		static void DrawBitmap(
			IntPtr ctx,
			IntPtr bitmap,
			float x,
			float y,
			float w,
			float h)
		@{
			CGContextDrawImage((CGContextRef)ctx, CGRectMake(x, x, w, h), (CGImageRef)bitmap);
		@}

		public static void Clear(this IntPtr ctx, int2 size, float4 color)
		{
			SetColor(ctx, color);
			Clear(ctx, size.X, size.Y);
		}

		[Foreign(Language.ObjC)]
		static void Clear(IntPtr ctx, int width, int height)
		@{
			CGContextClearRect((CGContextRef)ctx, { { 0.0f, 0.0f, }, { (CGFloat)width, (CGFloat)height } });
			CGContextFillRect((CGContextRef)ctx, { { 0.0f, 0.0f, }, { (CGFloat)width, (CGFloat)height } });
		@}

		public static void Draw(this IntPtr ctx, Internal.Circle circle)
		{
			var center = circle.Center;
			SetColor(ctx, circle.Color);
			DrawCircle(ctx, center.X, center.Y, circle.Radius);
		}

		[Foreign(Language.ObjC)]
		static void DrawCircle(
			IntPtr ctx,
			float centerX,
			float centerY,
			float radius)
		@{
			CGContextAddArc((CGContextRef)ctx, centerX, centerY, radius, 0, 360, 0);
			CGContextFillPath((CGContextRef)ctx);
		@}

		static void SetColor(IntPtr ctx, float4 color)
		{
			SetColor(ctx, color.X, color.Y, color.Z, color.W);
		}

		[Foreign(Language.ObjC)]
		static void Transform(
			IntPtr ctx, float a, float b, float c, float d, float tx, float ty)
		@{
			CGContextConcatCTM((CGContextRef)ctx, CGAffineTransformMake(a, b, c, d, tx, ty));
		@}

		[Foreign(Language.ObjC)]
		static void SaveGState(this IntPtr ctx)
		@{
			CGContextSaveGState((CGContextRef)ctx);
		@}

		[Foreign(Language.ObjC)]
		static void RestoreGState(this IntPtr ctx)
		@{
			CGContextRestoreGState((CGContextRef)ctx);
		@}

		[Foreign(Language.ObjC)]
		static void SetColor(IntPtr ctx, float r, float g, float b, float a)
		@{
			CGContextSetFillColorWithColor((CGContextRef)ctx, [UIColor colorWithRed:r green:g blue:b alpha:a].CGColor);
			CGContextSetStrokeColorWithColor((CGContextRef)ctx, [UIColor colorWithRed:r green:g blue:b alpha:a].CGColor);
		@}
	}
}
