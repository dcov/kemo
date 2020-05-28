use std::io::{Read};
use std::net::{TcpListener, TcpStream};
use std::thread;
use enigo::*;

fn key_click(enigo: &mut Enigo, buffer: &[u8], size: usize) {
    match String::from_utf8(Vec::from(&buffer[0..size])) {
        Ok(s) => {
            let c = s.chars().next().unwrap();
            enigo.key_click(Key::Layout(c));
        },
        Err(e) => {
            println!("Error decoding character key: {}", e);
        }
    }
}

fn handle_client(mut stream: TcpStream) {
    let mut enigo = Enigo::new();

    // We'll use a 4-byte buffer to allow for UTF-8 encoding.
    let mut buffer = [0 as u8; 4];
    loop {
        match stream.read(&mut buffer) {
            Ok(size) => {
                if size == 0 { continue }

                let first = buffer[0];

                if size == 1 {
                    if first & 0x80 == 0 {
                        key_click(&mut enigo, &buffer, size);
                        continue;
                    } 

                    if first & 0x40 == 0 {
                        enigo.mouse_click(MouseButton::Left);
                        continue;
                    } 

                    if first - 0xC0 == 0 {
                        enigo.mouse_click(MouseButton::Right);
                        continue;
                    } 

                    let scroll_y = if first & 0x20 == 0 {
                        (first - 0xC0) as i32
                    } else {
                        -((first - 0xE0) as i32)
                    };

                    enigo.mouse_scroll_y(scroll_y);
                    continue;
                } 

                if first & 0x80 == 1 {
                    key_click(&mut enigo, &buffer, size);
                }
                
                let second = buffer[1];

                let dx = if first & 0x40 == 0 {
                    first as i32
                } else {
                    -((first - 0x40) as i32)
                };

                let dy = if second & 0x40 == 0 {
                    second as i32
                } else {
                    -((second - 0x40) as i32)
                };

                enigo.mouse_move_relative(dx, dy);
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

