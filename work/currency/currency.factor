! Copyright (C) 2009 Wen-Chun Lin.
! See http://factorcode.org/license.txt for BSD license.
USING: formatting http.client sequences strings kernel io math regexp
unicode.case assocs ;

IN: currency

CONSTANT: coins {
    "TWD" "CNY" "JPY" "KRW"
    "HKD" "THB" "SGD" "IDR"
    "VND" "MYR" "PHP" "INR"
    "AED" "KWD" "AUD" "NZD"
    "USD" "CAD" "BRL" "MXN"
    "ARS" "CLP" "VEB" "EUR"
    "GBP" "RUB" "CHF" "SEK"
    "ZAR"
}

CONSTANT: calias H{ { "NTD" "TWD" } { "RMB" "CNY" } { "GRP" "GBP" } { "YEN" "JPY" } }

CONSTANT: yahootw-url "http://tw.money.yahoo.com/currency_exc_result?amt=%s&from=%s&to=%s"

CONSTANT: div-tag "            <div class"

: coins? ( coin -- ? )
    coins member? ;

: calias? ( alias -- ? )
    calias key? ;

: calias-at ( alias -- value/f ? )
    calias at* ;

: make-url ( money from to -- url )
    yahootw-url sprintf ;

: strip-em-tag ( str -- newstr )
    R! </?em>! "" re-replace ;

: calias>coin ( alias -- coin )
    calias-at [ ] [ drop coins first ] if ;

: >coin ( coin -- newcoin )
    dup coins? [ ] [ calias>coin ] if ;

: find-exchange ( str -- result )
    "經過計算後，" over start 7 + cut div-tag over start 0 spin subseq strip-em-tag nip ;

: get-ex-money ( money from to -- result )
    [ >upper >coin ] bi@ make-url http-get nip find-exchange ;
