//
//  CKMTransaction+SampleData.swift
//  CoinKeeper
//
//  Created by BJ Miller on 6/28/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

extension CKMTransaction {
  static func json() -> String {
    return """
    {
    "txid": "7f3a2790d59853fdc620b8cd23c8f68158f8bbdcd337a5f2451620d6f76d4e03",
    "hash": "ee90a9ec4bbcf1ab327a6489a74a393b85515bc5bf8d308a3201b19974445276",
    "size": 249,
    "vsize": 168,
    "weight": 669,
    "version": 1,
    "locktime": 0,
    "coinbase": false,
    "txinwitness": [],
    "blockhash": "0000000000000000007aba266efd9aedfc005b69539bf077d1eaffb4a5fb9272",
    "height": 1,
    "time": 1514906608,
    "blocktime": 1514906608,
    "vin": [
    {
    "txid": "69151603ebe4192d50c1aaaca4e0ab0ea335184e261376c2eda64c35ce9fd1b5",
    "vout": 1,
    "scriptSig": {
    "asm": "00142f0908d7a15b75bfacb22426b5c1d78f545a683f",
    "hex": "1600142f0908d7a15b75bfacb22426b5c1d78f545a683f"
    },
    "txinwitness": [
    "304402204dcaba494328bd472f4bf61761e43c9ca204ea81ce9c5c57d669e4ed4721499f022007a6024b0f5e202a7f38bb90edbecaa788e276239a12aa42d958818d52db3f9f",
    "036ebf6ab96773a9fa7997688e1712ddc9722ef9274220ba406cb050ac5f1a1306"
    ],
    "sequence": 4294967295,
    "previousoutput": {
    "value": 999934902,
    "n": 1,
    "scriptPubKey": {
    "asm": "OP_HASH160 4f7728b2a54dc9a2b44e47341e7e029bb99c7d72 OP_EQUAL",
    "hex": "a9144f7728b2a54dc9a2b44e47341e7e029bb99c7d7287",
    "reqSigs": 1,
    "type": "scripthash",
    "addresses": [
    "38wC41V2tNZrr2uiwUthn41b2M8SLGMVRt"
    ]
    }
    }
    }
    ],
    "vout": [
    {
    "value": 1,
    "n": 0,
    "scriptPubKey": {
    "asm": "OP_DUP OP_HASH160 54aac92eb2398146daa547d921ed29a63891a769 OP_EQUALVERIFY OP_CHECKSIG",
    "hex": "76a91454aac92eb2398146daa547d921ed29a63891a76988ac",
    "reqSigs": 1,
    "type": "pubkeyhash",
    "addresses": [
    "18igMXPZwZEZjNQm8JAtPfkUHY5UyQRRiD"
    ]
    }
    },
    {
    "value": 899764244,
    "n": 1,
    "scriptPubKey": {
    "asm": "OP_HASH160 cbb86d23f9555a9a2dd084a8feb928b85b927128 OP_EQUAL",
    "hex": "a914cbb86d23f9555a9a2dd084a8feb928b85b92712887",
    "reqSigs": 1,
    "type": "scripthash",
    "addresses": [
    "3LGC2ejYwgnV5SKz6vX7TjdCkPVifDTSX8"
    ]
    }
    }
    ]
    }
    """
  }

  static func singleSampleData() -> Data {
    return json().data(using: .utf8)!
  }

  static func multipleSampleData() -> Data {
    let newJson = "[" + json() + "]"
    return newJson.data(using: .utf8)!
  }
}
