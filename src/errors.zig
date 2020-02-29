pub const ImageError = error {
    InvalidMagicHeader,
    UnsupportedBitmapType,
    UnsupportedPixelFormat,
    UnsupportedImageFormat,
    AllocationFailed,
};

pub const ImageFormatInvalid = error.ImageFormatInvalid;