<?php // https://piehost.com/websocket/build-a-websocket-server-in-php-without-any-library
// Alternative: https://github.com/sirn-se/websocket-php/tree/v3.3-main
$host = 'pindadomo.local';
//$host = '192.168.129.2';
$port = 8080;

$socket = socket_create(AF_INET, SOCK_STREAM, SOL_TCP);
socket_set_option($socket, SOL_SOCKET, SO_REUSEADDR, 1);
socket_bind($socket, $host, $port);
socket_listen($socket);

$clients = [];

echo "WebSocket server started on $host:$port\n";

while (true) {
    $changedSockets = $clients;
    $changedSockets[] = $socket;

    $write = [];
    $except = [];

    socket_select($changedSockets, $write, $except, 0, 10);

    if (in_array($socket, $changedSockets)) {
        $newSocket = socket_accept($socket);
        $clients[] = $newSocket;
        $handshake = false;
        echo "New client connected\n";
        $socketKey = array_search($socket, $changedSockets);
        unset($changedSockets[$socketKey]);    }

    foreach ($changedSockets as $clientSocket) {
        $data = @socket_recv($clientSocket, $buffer, 1024, 0);
        if ($data === false || $data = 0) {
            echo "Client disconnected\n";
            $clientKey = array_search($clientSocket, $clients);
            unset($clients[$clientKey]);
            socket_close($clientSocket);
            continue;
        }

        if (!$handshake) {
            performHandshake($clientSocket, $buffer);
            $handshake = true;
        } else {
            $message = unmask($buffer);
// https://ably.com/topic/websockets#closing-a-web-socket-connection-at-the-protocol-level
//print_r (bin2hex($message));
            if (bin2hex($message) == "03e9") {  // dec 1001
              echo "Client going away\n";
              $clientKey = array_search($clientSocket, $clients);
              unset($clients[$clientKey]);
              socket_close($clientSocket);
            } elseif (!empty($message)) {
                echo "Received: $message\n";
                foreach ($clients as $client) {
                    if ($client != $clientSocket) {
                        sendMessage($client, $message);
                    }
                }
            }
        }
    }
}


function performHandshake($clientSocket, $headers) {
    $headers = parseHeaders($headers);
    $secKey = $headers['Sec-WebSocket-Key'];
    $secAccept = base64_encode(pack('H*', sha1($secKey . '258EAFA5-E914-47DA-95CA-C5AB0DC85B11')));
    $handshakeResponse = "HTTP/1.1 101 Switching Protocols\r\n" .
        "Upgrade: websocket\r\n" .
        "Connection: Upgrade\r\n" .
        "Sec-WebSocket-Accept: $secAccept\r\n\r\n";
    socket_write($clientSocket, $handshakeResponse, strlen($handshakeResponse));
}

// Parse HTTP Headers
function parseHeaders($headers) {
    $headers = explode("\r\n", $headers);
    $headerArray = [];
    foreach ($headers as $header) {
        $parts = explode(": ", $header);
        if (count($parts) === 2) {
            $headerArray[$parts[0]] = $parts[1];
        }
    }
    return $headerArray;
}

function unmask($payload)
{
    $length = ord($payload[1]) & 127;
    if ($length == 126) {
        $masks = substr($payload, 4, 4);
        $data = substr($payload, 8);
    } elseif ($length == 127) {
        $masks = substr($payload, 10, 4);
        $data = substr($payload, 14);
    } else {
        $masks = substr($payload, 2, 4);
        $data = substr($payload, 6);
    }
    $unmaskedtext = '';
    for ($i = 0; $i < strlen($data); ++$i) {
        $unmaskedtext .= $data[$i] ^ $masks[$i % 4];
    }
    return $unmaskedtext;
}

function sendMessage($clientSocket, $message)
{
    $message = mask($message);
    socket_write($clientSocket, $message, strlen($message));
}

function mask($message)
{
    $frame = [];
    $frame[0] = 129;

    $length = strlen($message);
    if ($length <= 125) {
        $frame[1] = $length;
    } elseif ($length <= 65535) {
        $frame[1] = 126;
        $frame[2] = ($length >> 8) & 255;
        $frame[3] = $length & 255;
    } else {
        $frame[1] = 127;
        $frame[2] = ($length >> 56) & 255;
        $frame[3] = ($length >> 48) & 255;
        $frame[4] = ($length >> 40) & 255;
        $frame[5] = ($length >> 32) & 255;
        $frame[6] = ($length >> 24) & 255;
        $frame[7] = ($length >> 16) & 255;
        $frame[8] = ($length >> 8) & 255;
        $frame[9] = $length & 255;
    }

    foreach (str_split($message) as $char) {
        $frame[] = ord($char);
    }

    return implode(array_map('chr', $frame));
}
