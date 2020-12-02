pub const ImageError = error{
    InvalidMagicHeader,
    UnsupportedBitmapType,
    UnsupportedPixelFormat,
    UnsupportedImageFormat,
    AllocationFailed,
};

pub const PngError = error{
    InvalidChunk,
    InvalidBitDepth,
    InvalidCRC,
    InvalidPalette,
};

pub const ImageFormatInvalid = error.ImageFormatInvalid;
