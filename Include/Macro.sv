`ifndef MACRO
`define MACRO

`define RNG(x) [(x) - 1 : 0]
`define ARR(t, w) t`RNG(w)
`define LOGIC(x) `ARR(logic, x)
`define BIT(x) `ARR(bit, x)
`define WIRE(x) `ARR(wire, x)
`define TRI(x) `ARR(tri, x)
`define MSB(x, width = BitWidth) x[(width) - 1]
`define LSB(x) x[0]
`define HIGH(x, width = BitWidth) x[(width) - 1 : (width) >> 1]
`define LOW(x, width = BitWidth) x[((width) >> 1) - 1 : 0]
`define ZERO(x) {(x){1'b0}}
`define ONE(x) {(x){1'b1}}
`define EXT(x, width = BitWidth) ((width)'(x))
`define SEXT(x, width = BitWidth) ((width)'(signed'(x)))
`define ZEXT(x, srcWidth, dstWidth) {{(dstWidth) - (srcWidth){1'bz}}, x}
`define ZEXTD(x, deltaWidth) {{deltaWidth{1'bz}}, x}

`endif