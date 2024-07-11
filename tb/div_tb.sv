`timescale 1ns/1ns

module div_tb;

  // Parameters
  parameter DATA_WIDTH = 32;

  // Signals
  logic clk;
  logic rst;
  logic [DATA_WIDTH-1:0] dividend;
  logic [DATA_WIDTH-1:0] divisor;
  logic [DATA_WIDTH-1:0] quotient;
  logic [DATA_WIDTH-1:0] remainder;
  logic division_finished;
  logic division_finished_lat;
  logic div_enable;

  // Instantiate DUT
  divider 
  #( 
    .size(DATA_WIDTH) 
  )
  dut (
    .clk(clk),
    .reset(rst),
    .dividend_i(dividend),
    .divisor_i(divisor),
    .div_enable_i(div_enable),
    .division_finished_out(division_finished),
    .result({remainder, quotient})
  );

  // Testbench code
  initial begin
    // Initialize signals
    clk = 0;
    rst = 1;
    dividend = 1;
    divisor = 1;
    div_enable = 1'b1;

    // Reset DUT
    #10 rst = 0;

    #10 div_enable = 1'b0;


    // Test random stimuli
    repeat(500) begin
      @(posedge clk)
      // Check result
      if (division_finished) begin
        
        if (divisor == 0) begin
          // Division by zero - expect quotient and remainder to be 0
          if (quotient !== 0 || remainder !== 0) begin
            $error("Division by zero failed");
          end
        end else begin
          // Compute expected result
          //{quotient, remainder} = dividend / divisor;

          // Check quotient and remainder
          if (quotient !== dividend / divisor || remainder !== dividend % divisor) begin
            $error("Division failed for dividend=%d divisor=%d quotient=%d remainder=%d",
                   dividend, divisor, quotient, remainder);
            $stop;
          end
          else begin
          $display("Division PASSED for dividend=%d divisor=%d quotient=%d remainder=%d",
                   dividend, divisor, quotient, remainder);
          end
        end

        // Reset signals for next test
        //rst = 1;
        //dividend = 1; // reseting causes errors
        //divisor  = 1; // reseting causes errors
        
        //#10 rst = 0;
      end
      // Wait for DUT to finish computing
      if (division_finished_lat == 'b1) begin
        dividend = $random;
        divisor  = $random;
        div_enable = 1'b1;
      end
      else begin
        div_enable = 1'b0;
      end
    end
    // End simulation
    $stop;
  end

  always_ff @(posedge clk) begin
      if (rst)
          division_finished_lat <= 'b0; // Reset q to 0 on reset
      else
          division_finished_lat <= division_finished; // Capture the input d on the rising edge of the clock
  end

  // Generate clock
  always #5 clk = ~clk;

endmodule
