using Uno;
using Uno.Compiler.ExportTargetInterop;
using Uno.UX;
using Uno.Threading;
using Uno.Collections;
using Fuse.Resources.Exif;
using Fuse.Input;
using Fuse.Scripting;
using Fuse.Controls.Internal;
using Fuse.Controls.Native.iOS;
using Fuse.Controls.Native.Android;

namespace Fuse.Controls
{
	extern(ANDROID) internal class Bitmap : IDisposable
	{
		public Java.Object Handle { get { return _handle; } }

		public int2 PixelSize { get { return int2(GetWidth(_handle), GetHeight(_handle)); } }

		Java.Object _handle;

		public Bitmap(byte[] bytes)
		{
			_handle = Load(Fuse.Android.Bindings.AndroidDeviceInterop.MakeBufferInputStream(bytes));
		}

		public Bitmap(Java.Object bitmap)
		{
			_handle = bitmap;
		}

		public void Dispose()
		{
			if (_handle != null)
			{
				Release(_handle);
				_handle = null;
			}
		}

		class SavePromise : Promise<string>
		{
			public void OnRejected(string msg) { Reject(new Exception(msg)); }
		}

		public Future<string> SaveJPG()
		{
			var sp = new SavePromise();
			SaveJPG(_handle, sp.Resolve, sp.OnRejected);
			return sp;
		}

		[Foreign(Language.Java)]
		static void SaveJPG(
			Java.Object handle,
			Action<string> onResolve,
			Action<string> onReject)
		@{
			String filePath;
			try {
				filePath = com.fusetools.camera.ImageStorageTools.createFilePath("jpeg", true);
				java.io.FileOutputStream file = new java.io.FileOutputStream(filePath);
				((android.graphics.Bitmap)handle).compress(
					android.graphics.Bitmap.CompressFormat.JPEG,
					100,
					file);
				file.close();
				onResolve.run(filePath);
			} catch(Exception e) {
				onReject.run(e.getMessage());
			}
		@}

		[Foreign(Language.Java)]
		static int GetWidth(Java.Object handle)
		@{
			return ((android.graphics.Bitmap)handle).getWidth();
		@}

		[Foreign(Language.Java)]
		static int GetHeight(Java.Object handle)
		@{
			return ((android.graphics.Bitmap)handle).getHeight();
		@}

		[Foreign(Language.Java)]
		static void Release(Java.Object handle)
		@{
			((android.graphics.Bitmap)handle).recycle();
		@}

		[Foreign(Language.Java)]
		static Java.Object Load(Java.Object buf)
		@{
			return android.graphics.BitmapFactory.decodeStream((java.io.InputStream)buf);
		@}
	}

	extern(iOS) internal class Bitmap : IDisposable
	{
		public IntPtr Handle { get { return _handle; } }

		public int2 PixelSize { get { return int2(GetWidth(_handle), GetHeight(_handle)); } }

		IntPtr _handle;

		public Bitmap(byte[] bytes)
		{
			_handle = Load(bytes);
		}

		public Bitmap(IntPtr handle)
		{
			_handle = handle;
		}

		class SavePromise : Promise<string>
		{
			public void OnRejected(string msg) { Reject(new Exception(msg)); }
		}

		public Future<string> SaveJPG()
		{
			var sp = new SavePromise();
			SaveJPG(_handle, sp.Resolve, sp.OnRejected);
			return sp;
		}

		public void Dispose()
		{
			if (_handle != IntPtr.Zero)
			{
				Release(_handle);
				_handle = IntPtr.Zero;
			}
		}

		[Foreign(Language.ObjC)]
		static void SaveJPG(
			IntPtr cgImage,
			Action<string> onResolve,
			Action<string> onReject)
		@{
			UIImage* uiImage = [UIImage imageWithCGImage:(CGImageRef)cgImage];
			NSData* data = UIImageJPEGRepresentation(uiImage, 1.0f);;
			NSString* ext = @"jpg";
			NSString* uuid = [[NSUUID UUID] UUIDString];
			NSString* dir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
			NSString* path = [NSString stringWithFormat:@"%@/IMG_%@.%@", dir, uuid, ext];

			NSError* error = nil;
			if (![data writeToFile:path options:NSDataWritingWithoutOverwriting error:&error]) {
				onReject([NSString stringWithFormat:@"%@", error]);
			} else {
				onResolve(path);
			}
		@}

		[Foreign(Language.ObjC)]
		static IntPtr Load(byte[] bytes)
		@{
			auto dataProvider = CGDataProviderCreateWithData(
				NULL,
				(const UInt8 *)bytes.unoArray->Ptr(),
				bytes.unoArray->Length(),
				NULL);
			auto cgImage = CGImageCreateWithJPEGDataProvider(
				dataProvider,
				NULL,
				true,
				kCGRenderingIntentDefault);
			CGDataProviderRelease(dataProvider);
			return cgImage;
		@}

		[Foreign(Language.ObjC)]
		static void Release(IntPtr cgImage)
		@{
			CGImageRelease((CGImageRef)cgImage);
		@}

		[Foreign(Language.ObjC)]
		static int GetWidth(IntPtr cgImage)
		@{
			return (int32_t)CGImageGetWidth((CGImageRef)cgImage);
		@}

		[Foreign(Language.ObjC)]
		static int GetHeight(IntPtr cgImage)
		@{
			return (int32_t)CGImageGetHeight((CGImageRef)cgImage);
		@}
	}
}
