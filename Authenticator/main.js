const OTP_REGEX = /otpauth:\/\/([ht]otp)\/(?:[a-zA-Z0-9%]+:)?([^\?]+)\?secret=([0-9A-Za-z]+)(?:.*(?:<?counter=)([0-9]+))?/

function parseUrl(url){
    let u = new URL(url)
    return {
        host: u.host,
        pathname: u.pathname,
        search: u.search,
        hash: u.hash,
    }
}

function isOTPUrl(url){
    return OTP_REGEX.test(url)
}

function parseOTP(url){
    let m = url.match(OTP_REGEX)
    return {
        type: m[1],
        name: m[2],
        secret: m[3]
    }
}
