pub const ImageError = error {
    InvalidMagicHeader,
    UnsupportedBitmapType,
    UnsupportedPixelFormat,
    AllocationFailed,
};