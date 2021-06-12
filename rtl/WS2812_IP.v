module WS2812_module #(
	parameter	FAMILY		 = "LIFCL",
	parameter   IF_USER_INTF = "APB"		  // Interface type "LMMI" "AHBL" or "APB"
)
(
	input wire  clk_i,
	input wire  resetn_i,
	
	output wire led_ctl_o,
	output reg  int_o,						// Interrupt
	output wire debug_o,
	
	input wire  apb_penable_i,				// apb Enable
	input wire  apb_psel_i,					// apb Slave select
	input wire  apb_pwrite_i,				// apb write 1, read 0
	input wire  [5:0]  apb_paddr_i,
	input wire  [31:0]  apb_pwdata_i,
	output reg  [31:0]  apb_prdata_o,
	output reg  apb_pslverr_o,				// apb slave error
	output reg  apb_pready_o
);

reg [5:0]  apb_paddr_r;
reg [31:0] status_register;
reg [31:0] control_register;

// State machine to control APB bus
reg [2:0] SM_APB;
localparam sm_idle   = 3'b000;
localparam sm_access = 3'b001;
localparam sm_ready  = 3'b010;

always @(posedge clk_i or negedge resetn_i) begin
	if (~resetn_i) begin
		SM_APB <= sm_idle;
		
		apb_prdata_o <= 32'b0;
		apb_pready_o <= 1'b0;
		apb_pslverr_o <= 1'b0;
		status_register <= 32'hADD00000;
		control_register <= 32'hADD00004;
		int_o <= 1'b0;
	end
	else begin
		case (SM_APB)
			sm_idle:
				begin
					int_o <= 1'b0;
					if (apb_psel_i && apb_penable_i) begin
						SM_APB <= sm_access;
						apb_pready_o <= 1'b1;

						if (apb_pwrite_i) begin
							int_o <= 1'b1;
							if (apb_paddr_i == 6'h0)
								status_register <= apb_pwdata_i;
							else
								control_register <= apb_pwdata_i;						
						end
						else begin
							// 0 = status register, 4 = control register
							if (apb_paddr_i == 6'h0)
								apb_prdata_o <= status_register;
							else
								apb_prdata_o <= control_register;
						end			
					end
				end
				
			sm_access:
				begin
					apb_pready_o <= 1'b0;
					SM_APB <= sm_idle;
				end

			sm_ready:
				begin
					SM_APB <= sm_idle;
					apb_pready_o <= 1'b0;
				end
		endcase
	end
end

assign led_ctl_o = control_register[0];
assign debug_o = apb_penable_i;
	
endmodule