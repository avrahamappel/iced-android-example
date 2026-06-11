use iced::{Size, window::Settings};
use todolist::application;

fn main() {

    application()
        .window(Settings {
            size: Size::new(432.0, 960.0),
            ..Default::default()
        })
        .run()
        .unwrap();
}
