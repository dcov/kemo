use std::io::{Read};
use std::net::{TcpListener, TcpStream};
use std::thread;
use enigo::*;

fn handle_client(mut stream: TcpStream) {
    let mut enigo = Enigo::new();

    // We'll use a 4-byte buffer to allow for UTF-8 encoding.
    let mut buffer = [0 as u8; 4];
    loop {
        match stream.read(&mut buffer) {
            Ok(size) => {
                if size == 0 { continue }

                let first = buffer[0];

                // If the MSB of the first byte is 0 then it's a UTF-8 encoded
                // character, else it's a mouse event.
                if first & 0x80 == 0 {
                    let s = match String::from_utf8(Vec::from(&buffer[0..size])) {
                        Ok(s) => s,
                        Err(e) => {
                            println!("Error decoding character key: {}", e);
                            continue
                        }
                    };

                    let c = s.chars().next().unwrap();
                    enigo.key_click(Key::Layout(c));

                } else if size == 1 {
                    if first & 0x1 == 0 {
                        enigo.mouse_click(MouseButton::Left);
                    } else {
                        enigo.mouse_click(MouseButton::Right);
                    }
                } else {
                    let second = buffer[1];

                    if second & 0x80 == 0 {
                    } else {
                        let dx = if first & 0x40 == 0 {
                            (first - 128) as i32
                        } else {
                            -((first - 192) as i32)
                        };

                        let dy = if second & 0x40 == 0 {
                            (second - 128) as i32
                        } else {
                            -((second - 192) as i32)
                        };

                        enigo.mouse_move_relative(dx, dy);
                    }
                }
            },
            Err(_) => {
                break
            }
        }
    }
}

fn main() {
    let listener = TcpListener::bind("0.0.0.0:5366").unwrap();
    println!("Kemo listening on port: 5366");

    for incoming in listener.incoming() {
        match incoming {
            Ok(stream) => {
                thread::spawn(move|| {
                    handle_client(stream);
                });
            },
            Err(e) => {
                println!("Connection error: {}", e);
            }
        }
    }
}

