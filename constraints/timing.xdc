# 100 MHz primary clock is declared once in board_common.xdc.
# pix_ce/tick_* are enables: do not declare generated clocks for them.
# Targeted asynchronous-control exceptions live in async_controls.tcl.
# Managed XDC files cannot contain conditional Tcl flow.

# TODO(A/C): Once actual SPI logic exists, derive external timing from the
# L3G4200D / ADC081S021 datasheets and actual sample edges/board wiring.
# TODO(B/C): Once VGA logic exists, document/validate external video timing.
# No blanket false path, artificial I/O delay or relaxed DRC is used to hide TODOs.
