module SyncAndEdge (
	input iClk,
	input iButton,
	input iRsn,
	input iEnClk,

	output oSyncButton
);

reg r0,r1;
reg r2,r3;

always @(posedge iClk or negedge iRsn) begin
	if(!iRsn) begin
		r0 <= 0;
		r1 <= 0;
	end
	else begin
	r0 <= iButton;
	r1 <= r0;
	end
end

always @(posedge iClk or negedge iRsn) begin
	if(!iRsn) begin
		r2 <= 0;
		r3 <= 0;
	end
	else if(iEnClk) begin
		r2 <= r1;
		r3 <= r2;
	end
end

//faling edge detector
assign oSyncButton = ~r2 & r3;

endmodule