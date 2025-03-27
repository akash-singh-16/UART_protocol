`timescale 1ns / 1ps

`include "uarttx.sv"
`include "uartrx.sv"
module i2c_top(
  input clk,rst,newd,op,
  input[6:0] addr, 
  input[7:0] din,
  output[7:0] dout,
  output busy,ack_err,
  output reg done
  );
  wire sda,scl;
  wire ack_errm,ack_errs;
  
  i2c_master master(clk,rst,newd,op,addr,din,sda,scl,dout,busy,ack_errm,done);
  i2c_slave slave(scl,clk,rst,sda,ack_errs,);
  
  assign ack_err= ack_errs|ack_errm;
endmodule 



module uart_top
  #(parameter clk_freq=1000000,
    parameter baud_rate=9600)
  (input clk,rst,rx,newd,
   input [7:0] dintx,
   output tx,donetx,donerx,
   output[7:0] doutrx
  );
  uartx#(clk_freq,baud_rate) utx(clk,rst,newd,dintx,tx,donetx);
  uartrx#(clk_freq,baud_rate) urx(clk,rst,rx,donerx,doutrx);
  
endmodule


interface uart_if;
  logic clk;
  logic uclktx;
  logic uclkrx;
  logic rst;
  logic rx;
  logic [7:0] dintx;
  logic newd;
  logic tx;
  logic [7:0] doutrx;
  logic donetx;
  logic donerx;
endinterface