/*
 * Bandera de Panamá - Tiny Tapeout VGA
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_vga_example(
  input  wire [7:0] ui_in,    // Dedicated inputs
  output wire [7:0] uo_out,   // Dedicated outputs
  input  wire [7:0] uio_in,   // IOs: Input path
  output wire [7:0] uio_out,  // IOs: Output path
  output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
  input  wire       ena,      // always 1 when the design is powered
  input  wire       clk,      // clock
  input  wire       rst_n     // reset_n - low to reset
);

  // VGA signals
  wire hsync, vsync, video_active;
  wire [9:0] pix_x;
  wire [9:0] pix_y;
  reg  [1:0] R, G, B;

  // TinyVGA PMOD
  assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};

  assign uio_out = 0;
  assign uio_oe  = 0;

  wire _unused_ok = &{ena, ui_in, uio_in};

  hvsync_generator hvsync_gen(
    .clk(clk),
    .reset(~rst_n),
    .hsync(hsync),
    .vsync(vsync),
    .display_on(video_active),
    .hpos(pix_x),
    .vpos(pix_y)
  );

  // ---------------------------------------------------------
  // Estrella: bitmap de 12x12, escalado x8 (96x96 píxeles)
  // ---------------------------------------------------------
  function [11:0] star_row(input [3:0] r);
    case (r)
      4'd0:  star_row = 12'b000001100000;
      4'd1:  star_row = 12'b000011110000;
      4'd2:  star_row = 12'b000011110000;
      4'd3:  star_row = 12'b111111111111;
      4'd4:  star_row = 12'b011111111110;
      4'd5:  star_row = 12'b001111111100;
      4'd6:  star_row = 12'b000111111000;
      4'd7:  star_row = 12'b000111111000;
      4'd8:  star_row = 12'b001111111100;
      4'd9:  star_row = 12'b001110011100;
      4'd10: star_row = 12'b011100001110;
      4'd11: star_row = 12'b011000000110;
      default: star_row = 12'b0;
    endcase
  endfunction

  // Estrella 1: centro en (160,120) -> esquina (112,72)
  wire [9:0] x1 = pix_x - 10'd112;
  wire [9:0] y1 = pix_y - 10'd72;
  wire in1 = (pix_x >= 10'd112) && (pix_x < 10'd208) &&
             (pix_y >= 10'd72)  && (pix_y < 10'd168);
  wire [11:0] row1 = star_row(y1[6:3]);
  wire star1 = in1 & row1[4'd11 - x1[6:3]];

  // Estrella 2: centro en (480,360) -> esquina (432,312)
  wire [9:0] x2 = pix_x - 10'd432;
  wire [9:0] y2 = pix_y - 10'd312;
  wire in2 = (pix_x >= 10'd432) && (pix_x < 10'd528) &&
             (pix_y >= 10'd312) && (pix_y < 10'd408);
  wire [11:0] row2 = star_row(y2[6:3]);
  wire star2 = in2 & row2[4'd11 - x2[6:3]];

  // ---------------------------------------------------------
  // Cuadrantes
  // ---------------------------------------------------------
  wire left = (pix_x < 10'd320);
  wire top  = (pix_y < 10'd240);

  always @(*) begin
    {R, G, B} = 6'b000000;
    if (video_active) begin
      if (top && left)        // Blanco con estrella azul
        {R, G, B} = star1 ? 6'b00_00_11 : 6'b11_11_11;
      else if (top && !left)  // Rojo
        {R, G, B} = 6'b11_00_00;
      else if (!top && left)  // Azul
        {R, G, B} = 6'b00_00_11;
      else                    // Blanco con estrella roja
        {R, G, B} = star2 ? 6'b11_00_00 : 6'b11_11_11;
    end
  end

endmodule
