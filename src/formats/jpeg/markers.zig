
//! Marker codes, see t-81 section B.1.1.3

const Markers = enum(u16) {
    // Start of Frame markers, non-differential, Huffman coding
    sof0 = 0xFFC0, // Baseline DCT
    sof1 = 0xFFC1, // Extended sequential DCT
    sof2 = 0xFFC2, // Progressive DCT
    sof3 = 0xFFC3, // Lossless sequential

    // Start of Frame markers, differential, Huffman coding
    sof5 = 0xFFC5, // Differential sequential DCT
    sof6 = 0xFFC6, // Differential progressive DCT
    sof7 = 0xFFC7, // Differential lossless sequential

    // Start of Frame markers, non-differential, arithmetic coding
    sof9 = 0xFFC9, // Extended sequential DCT
    sof10 = 0xFFCA, // Progressive DCT
    sof11 = 0xFFCB, // Lossless sequential

    // Start of Frame markers, differential, arithmetic coding
    sof13 = 0xFFCD, // Differential sequential DCT
    sof14 = 0xFFCE, // Differential progressive DCT
    sof15 = 0xFFCF, // Differential lossless sequential

    define_huffman_tables = 0xFFC4,
    define_arithmetic_coding = 0xFFCC,

    // 0xFFD0-0xFFD7: Restart markers, add as needed

    start_of_image = 0xFFD8,
    end_of_image = 0xFFD9,
    start_of_scan = 0xFFDA,
    define_quantization_tables = 0xFFDB,
    define_number_of_lines = 0xFFDC,
    define_restart_interval = 0xFFDD,
    define_hierarchical_progression = 0xFFDE,
    expand_reference_components = 0xFFDF,

    // 0xFFE0-0xFFEF application segments markers add 0-15 as needed.
    application0 = 0xFFE0,

    // 0xFFF0-0xFFFD jpeg extension markers add 0-13 as needed.
    jpeg_extension0 = 0xFFF0,
    comment = 0xFFFE,

    // reserved markers from 0xFF01-0xFFBF, add as needed
};