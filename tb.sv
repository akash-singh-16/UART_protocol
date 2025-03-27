`timescale 1ns / 1ps

class transaction;
  typedef enum bit {write=1'b0,read=1'b1} oper_type;
  randc oper_type oper;
  bit rx;
  rand bit [7:0] dintx;
  bit newd;
  bit tx;
  bit donetx;
  bit donerx;
  bit [7:0] doutrx;
  
  function transaction copy();
    copy=new();
    copy.oper=this.oper;
    copy.rx=this.rx;
    copy.dintx=this.dintx;
    copy.newd=this.newd;
    copy.tx=this.tx;
    copy.donetx=this.donetx;
    copy.donerx=this.donerx;
    copy.doutrx=this.doutrx;   
  endfunction
endclass


class generator;
  transaction tr;
  mailbox #(transaction) mbx;
  event done;
  int count=0;
  event drvnext;
  event sconext;
  
  function new(mailbox #(transaction) mbx);
   this.mbx=mbx;
   tr=new();
  endfunction
  
  task run();
    repeat(count) begin
      assert(tr.randomize) else $error("Randomization Failed");
      mbx.put(tr.copy);
      $display("[GEN] : Operation : %0s, Data In = %0d", tr.oper.name(),tr.dintx);
      @(drvnext);  
      @(sconext);
    end
    ->done;
  endtask 
endclass

class driver;
  virtual uart_if vif;
  transaction tr;
  mailbox #(transaction) mbx;
  mailbox #(bit [7:0]) mbxds;
  event drvnext;
  bit [7:0] din;
  bit wr=0;
  bit [7:0] datarx;
  
  function new(mailbox #(transaction) mbx, mailbox #(bit [7:0]) mbxds);
    this.mbx=mbx;
    this.mbxds=mbxds;
  endfunction
  
  task reset();
    vif.rst<=1'b1;
    vif.dintx<=1'b0;
    vif.newd<=1'b0;
    vif.rx<=1'b1;
    
    repeat (5) @(posedge vif.clk);
    vif.rst<=0;
    @(posedge vif.clk);
    $display("[DRV] : Reset Done");
    $display("--------------------------");
  endtask
  
  task run();
    forever begin
      mbx.get(tr);
      if(!tr.oper) begin
        @(posedge vif.uclktx);
        vif.rst<=1'b0;
        vif.newd<=1'b1;
        vif.rx<=1'b1;
        vif.dintx=tr.dintx;
        @(posedge vif.uclktx);
        vif.newd<=1'b0;
        mbxds.put(tr.dintx);
        $display("[DRV] : Data Sent = %0d",tr.dintx);
        wait(vif.donetx==1'b1);
        ->drvnext;
      end
      else if(tr.oper) begin
        @(posedge vif.uclkrx);
        vif.rst<=1'b0;
        vif.newd<=1'b0;
        vif.rx<=1'b0;
        @(posedge vif.uclkrx);
        for(int i=0; i<=7;i++) begin
          @(posedge vif.uclkrx);
          vif.rx<=$urandom;
          datarx[i]=vif.rx;
        end
        mbxds.put(datarx);
        $display("[DRV] : Data Recieved = %0d",datarx);
        wait(vif.donerx==1'b1);
        vif.rx<=1'b1;
        ->drvnext;
      end
      end
  endtask
endclass

class monitor;
  virtual uart_if vif;
  transaction tr;
  mailbox #(bit [7:0]) mbxms;
  bit[7:0] mtx;
  bit[7:0] mrx;
  
  function new(mailbox #(bit [7:0]) mbxms);
  	this.mbxms=mbxms;  
  endfunction
  
  task run();
    forever begin
      @(posedge vif.uclktx);
      if((vif.newd==1'b1)&&(vif.rx==1'b1)) begin
        @(posedge vif.uclktx);
        for(int i=0;i<=7;i++) begin
          @(posedge vif.uclktx);
          mtx[i]=vif.tx;
        end
        $display("[MON] : Data Send on UART tx = %0d",mtx);
        @(posedge vif.uclktx);
        mbxms.put(mtx);
      end
      
      else if((vif.newd==1'b0)&&(vif.rx==1'b0)) 
       begin
         wait(vif.donerx==1'b1);
         mrx=vif.doutrx;
         $display("[MON] : Data Recieved on UART rx = %0d",mrx);
         @(posedge vif.uclkrx);
         mbxms.put(mrx);
       end
    end
    
  endtask
  
endclass

class scoreboard;
  mailbox #(bit[7:0]) mbxms,mbxds;
  bit[7:0] ds,ms;
  
  event sconext;
  
  function new(mailbox #(bit [7:0]) mbxms,mailbox #(bit[7:0])mbxds);
    this.mbxms=mbxms;
    this.mbxds=mbxds;
  endfunction
  task run();
    forever begin
      mbxms.get(ms);
      mbxds.get(ds);
      if(ds==ms) $display("[SCO] : Data Matched");
      else $display("[SCO] : Data Mismatched");
      $display("----------------------------");
    ->sconext;
       end
  endtask
endclass

class environment;
  virtual uart_if vif;
  generator gen;
  driver drv;
  monitor mon;
  scoreboard sco;
  
  event nextgd;
  event nextgs;
  
  mailbox #(transaction) mbxgd;
  mailbox #(bit[7:0]) mbxms,mbxds;
  
  function new(virtual uart_if vif);
  mbxgd=new();
  mbxms=new();
  mbxds=new();
  gen=new(mbxgd);
  drv=new(mbxgd,mbxds);
  mon=new(mbxms);
  sco=new(mbxms,mbxds);
  this.vif=vif;
  drv.vif=this.vif;
  mon.vif=this.vif;
  gen.sconext=nextgs;
  sco.sconext=nextgs;
  gen.drvnext=nextgd;
  drv.drvnext=nextgd;
  endfunction
  
  task pre_test();
    drv.reset();
  endtask
  
  task test();
    fork
    gen.run();
    drv.run();
    mon.run();
    sco.run();
    join_any
  endtask

  task post_test();
    wait(gen.done.triggered);
    $finish();
  endtask
  
  task run();
    pre_test();
    test();
    post_test();
  endtask
  
endclass

module tb;
  uart_if vif();
  
  uart_top #(1000000,9600) dut(vif.clk,vif.rst,vif.rx,vif.newd,vif.dintx,vif.tx,vif.donetx,vif.donerx,
  vif.doutrx);
  
  initial begin
    vif.clk<=0;
  end
  
  always #10 vif.clk=~vif.clk;
  
  assign vif.uclktx=dut.utx.uclk;
  assign vif.uclkrx=dut.urx.uclk;
  
  environment env;
  
  initial begin
    env=new(vif);
    env.gen.count=25;
    env.run();
  end
  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars();
  end
endmodule