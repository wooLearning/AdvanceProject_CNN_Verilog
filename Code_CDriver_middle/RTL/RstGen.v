module RstGen (
	input iClk,
	input iButton,
	output oRsn
);

reg r0,r1;

always @(posedge iClk) begin
	r0 <= iButton;
	r1 <= r0;
end

assign oRsn = r1;

endmodule