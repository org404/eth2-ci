use grammers_tl_types::types::{InputPeerChat, MessageEntityCode};
use grammers_tl_types::enums::{InputPeer, MessageEntity};
use grammers_client::types::Message;
use grammers_client::{Client, Config};
use grammers_session::Session;
use simple_logger::SimpleLogger;
use core::time::Duration;
use tokio::time::sleep;
use tokio::{runtime};

extern crate redis;
use redis::Commands;

use sha3::{Digest, Sha3_256};
use std::env;
use std::fs;
use hex;
use log;

type Result = std::result::Result<(), Box<dyn std::error::Error>>;

async fn async_main() -> Result {
    SimpleLogger::new()
        .with_level(log::LevelFilter::Debug)
        .init()
        .unwrap();

    let api_id = env::var("TG_ID")?.parse().expect("TG_ID invalid");
    let api_hash = env::var("TG_HASH")?.to_string();
    let token = env::var("BOT_TOKEN")?.to_string();

    println!("Connecting to Telegram...");
    let mut client = Client::connect(Config {
        session: Session::load_or_create("eth2-CI.session")?,
        api_id,
        api_hash: api_hash.clone(),
        params: Default::default(),
    })
    .await?;
    println!("Connected!");

    if !client.is_authorized().await? {
        println!("Signing in...");
        client.bot_sign_in(&token, api_id, &api_hash).await?;
        println!("Signed in!");
    }

    // Ok(()) // @nocheckin
    println!("Connecting to Redis...");
    let rclient = redis::Client::open(format!("redis://{}/", env::var("REDIS_HOST")?))?;
    let mut file_cache = rclient.get_connection()?;
    println!("Connection ready.");

    println!("Starting infinite file-monitoring loop...");
    loop {
        let paths = fs::read_dir("/crashes".to_string()).unwrap();
        //let paths = fs::read_dir(env::var("PATH_TO_FOLDER")?.to_string()).unwrap();
        for path in paths {
            let path_name = path.unwrap().path().file_name().unwrap().to_os_string().into_string().unwrap();
            // if not a crash file -> skip
            if !path_name.starts_with("crash-") { /* println!("Skipping {}..", path_name); */ continue; }

            // create a sha3-256 hash for "checking in" already seen files
            let hash_b = Sha3_256::digest(path_name.clone().as_bytes());
            let hash = hex::encode(hash_b);

            if !file_cache.exists(hash.clone())? {
                // send message to telegram
                let mut text = format!("Found crash!\n\nFile: `{}`", path_name);
                
                // extremely hacky? but i have to freestyle it for now
                fn gen_entities(text: String) -> Vec<MessageEntity> {
                    let mut entities: Vec<MessageEntity> = Vec::new();
                    let offset: i32 = text.find("`").unwrap() as i32;
                    let length: i32 = text.rfind("`").unwrap() as i32 - offset - 1;
                    entities.push(MessageEntity::Code(MessageEntityCode {
                        offset: offset,
                        length: length,
                    }));
                    entities
                }

                // figure out entities
                let entities = gen_entities(text.clone());
                text = text.as_mut_str().replace("`", "");
                client.send_message(InputPeer::Chat(InputPeerChat { chat_id: 466964523 }), Message::text(text).entities(entities)).await?;
                // add to the cache
                let _ : () = file_cache.set(hash.clone(), true)?;
            }
        }
        sleep(Duration::from_secs(5)).await;
    }
}

fn main() -> Result {
    runtime::Builder::new_current_thread()
        .enable_all()
        .build()
        .unwrap()
        .block_on(async_main())
}
