#![no_std]
#![no_main]
use core::panic::PanicInfo;
use hippomenes_rt as _;

#[rtic::app(device = hippomenes_core)]
mod app {
    use core::fmt::Write;
    use hippomenes_core::UART;

    #[shared]
    struct Shared {
        uart: UART,
    }

    #[init]
    fn init() -> Shared {
        let peripherals = unsafe { hippomenes_core::Peripherals::steal() };
        let timer = peripherals.timer;
        let mut uart = peripherals.uart;
        write!(uart, "init").ok();
        timer.write(0x400F); //timer interrupt every
                             // 500*2^15 ~ 16M cycles ~0.75s @ 20MHz
        Shared { uart }
    }

    #[task(binds = Interrupt0, priority=2, shared=[uart])]
    struct Task1;

    impl RticTask for Task1 {
        fn init() -> Self {
            Self
        }

        fn exec(&mut self) {
            self.shared().uart.lock(|uart| {
                write!(uart, "T").ok();
                write!(uart, "1").ok();
            });

            rtic::export::pend(hippomenes_core::Interrupt1);

            self.shared().uart.lock(|uart| {
                write!(uart, "T").ok();
                write!(uart, "2").ok();
            });
        }
    }

    #[task(binds = Interrupt1, priority=1, shared=[uart])]
    struct Task2;

    impl RticTask for Task2 {
        fn init() -> Self {
            Self
        }

        fn exec(&mut self) {
            self.shared().uart.lock(|uart| {
                write!(uart, "T").ok();
                write!(uart, "3").ok();
            });
        }
    }
}

#[panic_handler]
fn p(_: &PanicInfo) -> ! {
    loop {}
}
