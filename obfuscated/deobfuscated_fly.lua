-- deobfuscated
local Env = getfenv();
local o = {};
local v1 = {...};
local r1 = true;
local r2 = string.gmatch;
local function r3(...)
    error("Tamper Detected!");
    return; 
end;
local r4 = false;
local v2 = pcall(function(...)
    r4 = true;
    return; 
end);
local v3 = v2;
if v2 then
    v3 = r4;
end;
local v4 = 1;
local r5 = math.random;
local v5 = table.concat;
local v6 = table;
local function v7(...)
    while true do
        l1 = l2;
        l2 = l1;
        r3(); 
    end;
    return; 
end;
if v6 then
    c = table.unpack;
end;
local v8 = v5;
local r6 = v6 or unpack;
local r7 = r5(3, 65);
local v9 = {
    pcall(function(...)
        return "diyVvWMMVEdc" / (6266514 - "5mPHqqb" ^ 3463869); 
    end)
};
local v10 = v9[2];
local r8 = tonumber(r2(tostring(v10), ":(%d*):")());
for F = 1, r7 do
    r9 = F;
    r10 = math.random(1, 100);
    r11 = r5(0, 255);
    r12 = r5(1, r10);
    r13 = r5(1, 2) == 1;
    r14 = v10.gsub(v10, ":(%d*):", ":" .. tostring(r5(0, 10000)) .. ":");
    L = {
        pcall(function(...)
            if r5(1, 2) == 1 or r9 == r7 then
                r1 = r1 and r8 == tonumber(r2(tostring(({
                    pcall(function(...)
                        return "du9fuv" / (1982637 - "gFzQunB" ^ 8890365); 
                    end)
                })[2]), ":(%d*):")());
            end;
            if r13 then
                error(r14, 0);
            end;
            v1 = {};
            for N = 1, r10 do
                v1[N] = r5(0, 255); 
            end;
            v1[r12] = r11;
            return r6(v1); 
        end)
    };
    if r13 then
        r1 = r1 and (pcall(function(...)
            if r5(1, 2) == 1 or r9 == r7 then
                r1 = r1 and r8 == tonumber(r2(tostring(({
                    pcall(function(...)
                        return "du9fuv" / (1982637 - "gFzQunB" ^ 8890365); 
                    end)
                })[2]), ":(%d*):")());
            end;
            if r13 then
                error(r14, 0);
            end;
            v1 = {};
            for N = 1, r10 do
                v1[N] = r5(0, 255); 
            end;
            v1[r12] = r11;
            return r6(v1); 
        end) == false and L[2] == r14);
    end; 
end;
r1 = r1 and 0 == 0;
if r1 then
    r17 = math.floor;
    r18 = 0;
    v9 = {};
    r19 = 2;
    r20 = {};
    v6 = 0;
    for t = 1, 256 do
        v9[t] = t; 
    end;
    v10 = #v9 == 0;
    t = table.remove(v9, math.random(1, #v9));
    r20[t] = string.char(t - 1);
    if #v9 == 0 then
        r21 = {};
        bS[10] = "r\x1ei\xe9\xf6\x7f\xc2b\x1f\xc8\x8f\x83\xc2}\t";
        r23 = {};
        r15 = setmetatable({}, {
            ["__index"] = r23,
            ["__metatable"] = nil
        });
        N = game;
        r24 = N.GetService(N, "RunService");
        P = game;
        r25 = P.GetService(P, "UserInputService");
        v4 = game;
        r26 = v4.GetService(v4, "StarterGui");
        v2 = game;
        r27 = v2.GetService(v2, "TweenService");
        v7 = game;
        bS[6] = "\xc7\xc3\x1f\xc7\xe2+\xe4S\x11\xd0I6\xfb\xae\xe0";
        r28 = v7.GetService(v7, "HttpService");
        c = game;
        bS[20] = "\x90.\xc3\xfd\xfej\xff\xbe\xac\x8d\xe7\x9c\x07\x18\xb3";
        r29 = c.GetService(c, "Players").LocalPlayer;
        r33 = 1;
        r34 = 1;
        r35 = 1;
        r36 = 1;
        r37 = true;
        r38 = false;
        r39 = false;
        r40 = 0;
        r41 = -1;
        bS[19] = 27095392891209;
        bS[16] = "\xda\x14!\xca$/\x80c\x06\x00\xf5au@P";
        bS[8] = "\xdd\xb8q\xa1\xc9\xb1\x9b\xff^\x97\x05\x8f\xc1[\n";
        bS[30] = "\xfa\xb2\xf6\x82\xf8~\xe5/\x99\xc9\xbdd\xe3\xbb<";
        bS[27] = 75833065507;
        bS[15] = 25600554086033;
        r42 = {
            ["ToggleFlight"] = Enum.KeyCode.v3,
            ["CycleBoost"] = Enum.KeyCode.Q,
            ["OpenUI"] = Enum.KeyCode.U,
            ["FlyForward"] = Enum.KeyCode.W,
            ["FlyBackward"] = Enum.KeyCode.S,
            ["FlyLeft"] = Enum.KeyCode.A,
            ["FlyRight"] = Enum.KeyCode.D,
            ["Ascend"] = Enum.KeyCode.Space,
            ["Descend"] = Enum.KeyCode.LeftShift
        };
        r43 = r42;
        r44 = "FlightAnimator_Settings.json";
        r45 = false;
        bS[13] = 11854342018448;
        r46 = 2;
        r47 = true;
        r48 = true;
        r49 = .8;
        r50 = 2.9;
        r51 = r49;
        r52 = r50;
        r53 = 70;
        r54 = 95;
        r55 = 130;
        r56 = r53;
        r57 = r53;
        r58 = 5;
        bS[24] = "\x1f\xe5\x94\xdc=\xf9\x8cBy\xb4\xb0\xfd\xf9\xf9\x98";
        r59 = {
            ["F"] = 0,
            ["B"] = 0,
            ["L"] = 0,
            ["R"] = 0
        };
        r60 = 50;
        r61 = 100;
        r62 = r60;
        bS[14] = "\x8f>&\xb2\xe75Q\x8d\xf5H%5\xae\x87L";
        bS[3] = 17455291244480;
        bS[4] = "z\xecZ\x9c\xeb\x07\\\xc1/=\\\x86s\n\x1d";
        bS[11] = 19772141495287;
        bS[34] = "\xc8\x0c\x8f\xde\xf4\xfcm;\xc2\xe7\xc4 \xb6\x1fQ";
        bS[12] = "\x98\xc5j\x97\xe0\t\xf0\xf3\x9a\xc0\x91\xa2qG\x05";
        bS[25] = 2956739364192;
        bS[31] = 2234268861456;
        bS[29] = 28912776197271;
        bS[2] = "\x1c\x04y\xd5+\x00\x05\xdf:\x84?\xf0\x19\xfc\xb7";
        bS[17] = 19748662027244;
        bS[5] = 27454553485808;
        bS[32] = "7\\@0\x9eV\x96\xcb\xd9\xe6\xbc\x1f\xd0\xcdN";
        bS[1] = 34217571270205;
        bS[22] = "\xf8Bp\xcc4\xa6NL\xa2\x15\xcfU\xa3M\xe4";
        bS[23] = 30722371303394;
        bS[21] = 19157488460504;
        bS[7] = 7154519215363;
        bS[36] = "\xf4\xb7\xb3MI\x0b)\xe9\xc2\xcd\x87\xbctho";
        bS[33] = 7754425978394;
        bS[26] = "|w\x98!\xa9\xf5q\x9dx\x0c\xb3\xb1R\xc0\x93";
        bS[9] = 13490574497930;
        bS[1] = 16649386171976;
        bS[1] = r16(bS[2], bS[3]);
        bS[18] = "\x84\xb8vK\x06G\xebq\x88\xcb\x1fY_1U";
        bS[1] = 21090779096669;
        bS[3] = 25060959808917;
        bS[2] = "3IE\x93\xf5/\x98\xbf\x12\x808\xdc\x07";
        bS[1] = r16(bS[2], bS[3]);
        bS[1] = r15;
        bS[2] = r16;
        bS[3] = bS[2](bS[4], bS[5]);
        bS[1] = true;
        bS[3] = 17889551917194;
        bS[1] = 17053928890117;
        bS[5] = 13405135476834;
        bS[2] = "?\x87b\xe5\x06\xf3\xc9";
        bS[4] = "\xfdh\xae'\xfc\x9e\x1a!~\xad\xa3\xeaG";
        bS[1] = r16(bS[2], bS[3]);
        bS[1] = r15;
        bS[2] = r16;
        bS[3] = bS[2](bS[4], bS[5]);
        bS[1] = 1;
        bS[3] = r15;
        bS[4] = r16;
        bS[5] = bS[4](bS[6], bS[7]);
        bS[2] = bS[3][bS[5]];
        bS[3] = true;
        bS[5] = 714061119820;
        bS[37] = 16265616481686;
        bS[3] = 19915721106489;
        bS[1] = 1205600436785;
        bS[28] = "\xd2\xc6\xf9(\x94\xb0\xb8a\x14q\x8c:\xec\x19z";
        bS[4] = "\x01^\x87\x17A\xe8\xb0";
        bS[2] = "\xc7\xd7Q";
        bS[1] = r16(bS[2], bS[3]);
        bS[1] = r15;
        bS[6] = "\xe3M\x90\x88\xf1\xc7\x01\x1c\xa7?\xda\xad\xa4";
        bS[2] = r16;
        bS[3] = bS[2](bS[4], bS[5]);
        bS[3] = r15;
        bS[7] = 238799601775;
        bS[1] = true;
        bS[4] = r16;
        bS[5] = bS[4](bS[6], bS[7]);
        bS[2] = bS[3][bS[5]];
        bS[3] = 1;
        bS[5] = r15;
        bS[6] = r16;
        bS[7] = bS[6](bS[8], bS[9]);
        bS[4] = bS[5][bS[7]];
        bS[5] = true;
        bS[1] = 31005401675878;
        bS[9] = 35007747915693;
        bS[2] = 33391369403581;
        bS[6] = "\xa6\xd48U_m\xe9";
        bS[1] = "\xae3_p`Cx\xa7x\x8f\xfeF;F\x95\xd2?\x04M\xe69\x13\xb8\xf3Q\xbc\xc6\xe7";
        bS[4] = "r\x9aw";
        bS[3] = 17552456671213;
        bS[2] = "\x1ec;\x85g";
        bS[1] = r16(bS[2], bS[3]);
        bS[7] = 14856383470342;
        bS[5] = 9284566323427;
        bS[1] = r15;
        bS[2] = r16;
        bS[3] = bS[2](bS[4], bS[5]);
        bS[3] = r15;
        bS[4] = r16;
        bS[5] = bS[4](bS[6], bS[7]);
        bS[1] = 3.5;
        bS[2] = bS[3][bS[5]];
        bS[5] = r15;
        bS[3] = true;
        bS[8] = "\xe3=\xe2\xe73r \x98%\t\x92\xc6\xc1";
        bS[6] = r16;
        bS[7] = bS[6](bS[8], bS[9]);
        bS[4] = bS[5][bS[7]];
        bS[7] = r15;
        bS[5] = 1;
        bS[8] = r16;
        bS[9] = bS[8](bS[10], bS[11]);
        bS[6] = bS[7][bS[9]];
        bS[7] = true;
        bS[6] = "\xee\xd0!";
        bS[3] = 23705024703262;
        bS[1] = 18936224146033;
        bS[2] = "+n\x13\xe1\xe8\xd6)4>\xd2\xb7";
        bS[4] = 6596582018047;
        bS[1] = r16(bS[2], bS[3]);
        bS[8] = "\x17P\x1f\xa3\xae\xae\x1e";
        bS[1] = r16;
        bS[5] = 7649475939818;
        bS[3] = "\xe6\x80\x9c\"\xdb\xaf\x08\xca<\xb1\xeaB\x00\x94\x10;\xe9\xa9\xf9!\xfb2\x7fe'\xd1!";
        bS[2] = bS[1](bS[3], bS[4]);
        bS[4] = "\x99\x00\xd2\x9b\x07";
        bS[1] = r15;
        bS[9] = 31657541826965;
        bS[11] = 35104029442010;
        bS[2] = r16;
        bS[7] = 9611431694715;
        bS[3] = bS[2](bS[4], bS[5]);
        bS[1] = 0.5;
        bS[3] = r15;
        bS[4] = r16;
        bS[5] = bS[4](bS[6], bS[7]);
        bS[2] = bS[3][bS[5]];
        bS[3] = 3.5;
        bS[5] = r15;
        bS[6] = r16;
        bS[7] = bS[6](bS[8], bS[9]);
        bS[4] = bS[5][bS[7]];
        bS[5] = true;
        bS[7] = r15;
        bS[10] = "\xdd\x7f\xc7\xc0\x08\xf61\xa8\x9d\\\x92\x8b\x8c";
        bS[8] = r16;
        bS[9] = bS[8](bS[10], bS[11]);
        bS[6] = bS[7][bS[9]];
        bS[7] = 1;
        bS[9] = r15;
        bS[10] = r16;
        bS[11] = bS[10](bS[12], bS[13]);
        bS[8] = bS[9][bS[11]];
        bS[9] = true;
        bS[2] = "\x9b(\xe2|\xb3XV;\xfe\x96<\x8a\xb2\xea";
        bS[3] = 34533789384401;
        bS[1] = r16(bS[2], bS[3]);
        bS[5] = 29595623716309;
        bS[4] = "\xf78\xcb%\xca\xad\xd3\xaa\x0b\xe16";
        bS[7] = 16403346185686;
        bS[1] = r15;
        bS[2] = r16;
        bS[8] = "\x98\xa2\x1c";
        bS[3] = bS[2](bS[4], bS[5]);
        bS[2] = r15;
        bS[6] = 4258411300798;
        bS[5] = "\x04R\xcdG\xc5\x9d\xbe\x9f\x0c\tlW#\xdeK\xb9\x99\xd7&A\xa3\xbd\xc8\x1f\xa0\xfd\xc2";
        bS[3] = r16;
        bS[9] = 12300803528288;
        bS[4] = bS[3](bS[5], bS[6]);
        bS[1] = bS[2][bS[4]];
        bS[10] = "\xe7\xe6~\xfd\xf5\x15w";
        bS[6] = "P\x08\x1e\xc9I";
        bS[3] = r15;
        bS[4] = r16;
        bS[13] = 23557865401049;
        bS[11] = 17663546777633;
        bS[5] = bS[4](bS[6], bS[7]);
        bS[2] = bS[3][bS[5]];
        bS[5] = r15;
        bS[6] = r16;
        bS[7] = bS[6](bS[8], bS[9]);
        bS[3] = .1;
        bS[4] = bS[5][bS[7]];
        bS[5] = 4;
        bS[12] = "\xbc\x03\xee\x05=t\xd2\xbd\xe6&\xd7d\x14";
        bS[7] = r15;
        bS[8] = r16;
        bS[9] = bS[8](bS[10], bS[11]);
        bS[6] = bS[7][bS[9]];
        bS[9] = r15;
        bS[10] = r16;
        bS[7] = true;
        bS[11] = bS[10](bS[12], bS[13]);
        bS[8] = bS[9][bS[11]];
        bS[11] = r15;
        bS[12] = r16;
        bS[13] = bS[12](bS[14], bS[15]);
        bS[9] = 1;
        bS[10] = bS[11][bS[13]];
        bS[11] = true;
        bS[1] = r15;
        bS[6] = "\xe1S\x1b\xcb\x0b\x19\x83N\x9d!f";
        bS[7] = 15764941069485;
        bS[5] = 32058236566096;
        bS[2] = r16;
        bS[4] = "P\xd7\xae\xafNu";
        bS[3] = bS[2](bS[4], bS[5]);
        bS[3] = r15;
        bS[4] = r16;
        bS[9] = 16789585583754;
        bS[5] = bS[4](bS[6], bS[7]);
        bS[2] = bS[3][bS[5]];
        bS[7] = "1H\xda:\x9a\x14\xa0s\xfaT#\xd1\xeb\xf4\x14\\\xf7\x05\x87~\x1elV\xad\xadV\x88-";
        bS[4] = r15;
        bS[11] = 16479002189305;
        bS[5] = r16;
        bS[8] = 26806154522818;
        bS[6] = bS[5](bS[7], bS[8]);
        bS[3] = bS[4][bS[6]];
        bS[8] = "\xc9K\xa3\xa2\xdc";
        bS[10] = "\xe9g\x02";
        bS[5] = r15;
        bS[6] = r16;
        bS[7] = bS[6](bS[8], bS[9]);
        bS[4] = bS[5][bS[7]];
        bS[5] = 0;
        bS[13] = 27044954124593;
        bS[12] = "H\xd9p\xac\xcb\xdf\\";
        bS[7] = r15;
        bS[8] = r16;
        bS[9] = bS[8](bS[10], bS[11]);
        bS[14] = "v[Y\t\x97\x9c\xe1}\x87\xb7\xb3O\x8f";
        bS[6] = bS[7][bS[9]];
        bS[7] = 2;
        bS[9] = r15;
        bS[15] = 30280160081684;
        bS[10] = r16;
        bS[11] = bS[10](bS[12], bS[13]);
        bS[8] = bS[9][bS[11]];
        bS[11] = r15;
        bS[9] = true;
        bS[12] = r16;
        bS[13] = bS[12](bS[14], bS[15]);
        bS[10] = bS[11][bS[13]];
        bS[11] = .3;
        bS[13] = r15;
        bS[14] = r16;
        bS[15] = bS[14](bS[16], bS[17]);
        bS[12] = bS[13][bS[15]];
        bS[13] = true;
        bS[1] = {
            [bS[2]] = bS[3],
            [bS[4]] = bS[5],
            [bS[6]] = bS[7],
            [bS[8]] = bS[9],
            [bS[10]] = bS[11],
            [bS[12]] = bS[13]
        };
        bS[12] = "\x01&\x16";
        bS[3] = r15;
        bS[6] = "\x80\xb4\xb5\xed\x91\x9b\xaf\xda\xa8";
        bS[9] = 28487157380049;
        bS[4] = r16;
        bS[8] = "\x90\xe6L\x15\t\xabr*YD\x1f";
        bS[11] = 32150550018683;
        bS[7] = 22865983695255;
        bS[5] = bS[4](bS[6], bS[7]);
        bS[10] = 2116746593241;
        bS[2] = bS[3][bS[5]];
        bS[16] = "\xf7\xdb\xce\x89a2\xac)\xde8\xdd\x93\xa6";
        bS[15] = 1940122420103;
        bS[5] = r15;
        bS[6] = r16;
        bS[7] = bS[6](bS[8], bS[9]);
        bS[4] = bS[5][bS[7]];
        bS[6] = r15;
        bS[9] = "-F\x1d\xc9\x9bY\xef\x95`r\x8a\xa0\xac\xcd\x8d2\xd1n+T\xfe\x81\xd7E%\xf1o";
        bS[7] = r16;
        bS[17] = 16738319425138;
        bS[8] = bS[7](bS[9], bS[10]);
        bS[5] = bS[6][bS[8]];
        bS[10] = "d\x93\xc4C\x1b";
        bS[13] = 8159168745175;
        bS[14] = "\xc9[\x92_\"\x92\xf4";
        bS[7] = r15;
        bS[8] = r16;
        bS[9] = bS[8](bS[10], bS[11]);
        bS[6] = bS[7][bS[9]];
        bS[9] = r15;
        bS[7] = .1;
        bS[10] = r16;
        bS[11] = bS[10](bS[12], bS[13]);
        bS[8] = bS[9][bS[11]];
        bS[11] = r15;
        bS[9] = 3.5;
        bS[12] = r16;
        bS[13] = bS[12](bS[14], bS[15]);
        bS[10] = bS[11][bS[13]];
        bS[13] = r15;
        bS[14] = r16;
        bS[15] = bS[14](bS[16], bS[17]);
        bS[12] = bS[13][bS[15]];
        bS[13] = 1;
        bS[11] = true;
        bS[15] = r15;
        bS[16] = r16;
        bS[17] = bS[16](bS[18], bS[19]);
        bS[14] = bS[15][bS[17]];
        bS[15] = true;
        bS[3] = {
            [bS[4]] = bS[5],
            [bS[6]] = bS[7],
            [bS[8]] = bS[9],
            [bS[10]] = bS[11],
            [bS[12]] = bS[13],
            [bS[14]] = bS[15]
        };
        bS[5] = r15;
        bS[11] = 23334901443186;
        bS[6] = r16;
        bS[9] = 25645147123365;
        bS[10] = "\xf69wd\xb4\xfe69J\xe7\x08";
        bS[8] = "\x04\x88\xcb\xb5\xe4\"\x82\xf7\xc5\x82\x10j";
        bS[7] = bS[6](bS[8], bS[9]);
        bS[16] = "\x98qJw\xf5M\x9e";
        bS[13] = 72206712865;
        bS[4] = bS[5][bS[7]];
        bS[7] = r15;
        bS[8] = r16;
        bS[12] = 34744868847411;
        bS[9] = bS[8](bS[10], bS[11]);
        bS[11] = "rZ\x02T&D\xe3N\xa9l\xf3\xc3\x0byM\xebZ~D\xc9\x9f\x08\xef_z\xce\xd9";
        bS[6] = bS[7][bS[9]];
        bS[8] = r15;
        bS[9] = r16;
        bS[10] = bS[9](bS[11], bS[12]);
        bS[15] = 19808071164935;
        bS[18] = "Y\xb3\xbc\x89\xa1\x9b\xc9\xfd7h7>|";
        bS[19] = 11926548731313;
        bS[7] = bS[8][bS[10]];
        bS[9] = r15;
        bS[10] = r16;
        bS[12] = "RL5\x10\xc8";
        bS[11] = bS[10](bS[12], bS[13]);
        bS[8] = bS[9][bS[11]];
        bS[9] = .1;
        bS[11] = r15;
        bS[17] = 34664526184205;
        bS[12] = r16;
        bS[14] = "\x19\x1d\xbf";
        bS[13] = bS[12](bS[14], bS[15]);
        bS[10] = bS[11][bS[13]];
        bS[13] = r15;
        bS[14] = r16;
        bS[15] = bS[14](bS[16], bS[17]);
        bS[12] = bS[13][bS[15]];
        bS[11] = 4.5;
        bS[15] = r15;
        bS[16] = r16;
        bS[13] = true;
        bS[17] = bS[16](bS[18], bS[19]);
        bS[14] = bS[15][bS[17]];
        bS[15] = 1;
        bS[17] = r15;
        bS[18] = r16;
        bS[19] = bS[18](bS[20], bS[21]);
        bS[16] = bS[17][bS[19]];
        bS[17] = true;
        bS[5] = {
            [bS[6]] = bS[7],
            [bS[8]] = bS[9],
            [bS[10]] = bS[11],
            [bS[12]] = bS[13],
            [bS[14]] = bS[15],
            [bS[16]] = bS[17]
        };
        bS[13] = 16184960048496;
        bS[10] = "\xcb\x1f\x1aZ\xa4\xa6\x13\xc3W\xdeg";
        bS[11] = 29075777795299;
        bS[7] = r15;
        bS[8] = r16;
        bS[17] = 33848506826129;
        bS[18] = "\xef\xdc\xba[5A\x08";
        bS[9] = bS[8](bS[10], bS[11]);
        bS[12] = "d\xd6\xc8\xb60<\x89x\xac\xe3\xdc";
        bS[6] = bS[7][bS[9]];
        bS[15] = 6192209234755;
        bS[9] = r15;
        bS[14] = 376462540975;
        bS[10] = r16;
        bS[11] = bS[10](bS[12], bS[13]);
        bS[13] = "\x02\xa6\xc9\xcb\x8d\x83J9Y\xef$\xc9U\xea\xc9{\xab\x80\x93}\xe7v\x01\xa6;\xe7\x99\xbe";
        bS[16] = "\x91\x0fC";
        bS[8] = bS[9][bS[11]];
        bS[20] = "\x9a\xbc`F\x7f\x98\xb9d\xf0_\x02\xa8\xb1";
        bS[10] = r15;
        bS[11] = r16;
        bS[12] = bS[11](bS[13], bS[14]);
        bS[9] = bS[10][bS[12]];
        bS[11] = r15;
        bS[14] = "8\x8e\xd2\x03\xca";
        bS[12] = r16;
        bS[13] = bS[12](bS[14], bS[15]);
        bS[10] = bS[11][bS[13]];
        bS[21] = 31792763320788;
        bS[13] = r15;
        bS[11] = .1;
        bS[19] = 23934327942025;
        bS[14] = r16;
        bS[15] = bS[14](bS[16], bS[17]);
        bS[12] = bS[13][bS[15]];
        bS[15] = r15;
        bS[16] = r16;
        bS[17] = bS[16](bS[18], bS[19]);
        bS[13] = 2.8;
        bS[14] = bS[15][bS[17]];
        bS[15] = true;
        bS[17] = r15;
        bS[18] = r16;
        bS[19] = bS[18](bS[20], bS[21]);
        bS[16] = bS[17][bS[19]];
        bS[19] = r15;
        bS[20] = r16;
        bS[17] = .6;
        bS[21] = bS[20](bS[22], bS[23]);
        bS[18] = bS[19][bS[21]];
        bS[19] = true;
        bS[7] = {
            [bS[8]] = bS[9],
            [bS[10]] = bS[11],
            [bS[12]] = bS[13],
            [bS[14]] = bS[15],
            [bS[16]] = bS[17],
            [bS[18]] = bS[19]
        };
        bS[13] = 4514896906294;
        bS[18] = "\xa8#/";
        bS[14] = "\xfaL\xe46\x07\xf9\xd8Q\xed\x8e\xbb";
        bS[12] = "\x06\x1c\xb9.\xca\xe0\xc1P\xb4";
        bS[9] = r15;
        bS[20] = "\xc7\xf5\x85\x8b\xe4\x0e\xea";
        bS[10] = r16;
        bS[17] = 20993899111984;
        bS[11] = bS[10](bS[12], bS[13]);
        bS[8] = bS[9][bS[11]];
        bS[11] = r15;
        bS[12] = r16;
        bS[15] = 23414545738391;
        bS[13] = bS[12](bS[14], bS[15]);
        bS[16] = 12327584781932;
        bS[15] = "\xd1_\xf9\x93ek\xbf\t\nr\xa2u\x7f\xad;LX\x1ep7\xe0s\x1a\xbd\xe0s\x12\xae";
        bS[10] = bS[11][bS[13]];
        bS[12] = r15;
        bS[22] = "\xf1\xa5GPN\x0c:<\xd1G\xcd\x85>";
        bS[13] = r16;
        bS[14] = bS[13](bS[15], bS[16]);
        bS[21] = 7423372758400;
        bS[11] = bS[12][bS[14]];
        bS[13] = r15;
        bS[14] = r16;
        bS[16] = "\x96N!Mz";
        bS[15] = bS[14](bS[16], bS[17]);
        bS[12] = bS[13][bS[15]];
        bS[13] = .1;
        bS[15] = r15;
        bS[19] = 15275127757769;
        bS[16] = r16;
        bS[17] = bS[16](bS[18], bS[19]);
        bS[14] = bS[15][bS[17]];
        bS[17] = r15;
        bS[18] = r16;
        bS[23] = 5558189034012;
        bS[19] = bS[18](bS[20], bS[21]);
        bS[15] = 2;
        bS[16] = bS[17][bS[19]];
        bS[19] = r15;
        bS[17] = true;
        bS[20] = r16;
        bS[21] = bS[20](bS[22], bS[23]);
        bS[18] = bS[19][bS[21]];
        bS[21] = r15;
        bS[22] = r16;
        bS[19] = 1;
        bS[23] = bS[22](bS[24], bS[25]);
        bS[20] = bS[21][bS[23]];
        bS[21] = true;
        bS[9] = {
            [bS[10]] = bS[11],
            [bS[12]] = bS[13],
            [bS[14]] = bS[15],
            [bS[16]] = bS[17],
            [bS[18]] = bS[19],
            [bS[20]] = bS[21]
        };
        bS[17] = 7674935627253;
        bS[11] = r15;
        bS[12] = r16;
        bS[15] = 726158033234;
        bS[14] = "G\xe4\xbe\x96\x0c\x1at\x1a`";
        bS[13] = bS[12](bS[14], bS[15]);
        bS[19] = 8885326778409;
        bS[10] = bS[11][bS[13]];
        bS[18] = 35107289382876;
        bS[21] = 9615058047357;
        bS[13] = r15;
        bS[16] = "S\x8c\xb9\xe3\xeb>\xfd\x11T}\xfa";
        bS[14] = r16;
        bS[15] = bS[14](bS[16], bS[17]);
        bS[12] = bS[13][bS[15]];
        bS[14] = r15;
        bS[15] = r16;
        bS[17] = "\xb6=z\x8cP\x9dW\xdf\xce(O\xdb\x08:e\xaa.\xc2\xdc\xe7vh/*_D\x9b";
        bS[16] = bS[15](bS[17], bS[18]);
        bS[13] = bS[14][bS[16]];
        bS[22] = "\xd4@\x1d\xca\xbe\xda\xa4";
        bS[18] = "\x1cn\xea\xe3 ";
        bS[15] = r15;
        bS[16] = r16;
        bS[17] = bS[16](bS[18], bS[19]);
        bS[14] = bS[15][bS[17]];
        bS[17] = r15;
        bS[15] = .1;
        bS[20] = "l\xd8\xea";
        bS[23] = 16661236702798;
        bS[18] = r16;
        bS[19] = bS[18](bS[20], bS[21]);
        bS[16] = bS[17][bS[19]];
        bS[17] = 2;
        bS[19] = r15;
        bS[20] = r16;
        bS[21] = bS[20](bS[22], bS[23]);
        bS[18] = bS[19][bS[21]];
        bS[19] = true;
        bS[24] = "\xfa\xaa/\xff\xed\xb9X\xfd\x89T\xf06W";
        bS[25] = 796347564402;
        bS[21] = r15;
        bS[22] = r16;
        bS[23] = bS[22](bS[24], bS[25]);
        bS[20] = bS[21][bS[23]];
        bS[23] = r15;
        bS[24] = r16;
        bS[25] = bS[24](bS[26], bS[27]);
        bS[21] = .3;
        bS[22] = bS[23][bS[25]];
        bS[23] = true;
        bS[26] = "\x9czD\xef\x0b\r\xe9\xb3\xd5\x06\xf8K\x17";
        bS[11] = {
            [bS[12]] = bS[13],
            [bS[14]] = bS[15],
            [bS[16]] = bS[17],
            [bS[18]] = bS[19],
            [bS[20]] = bS[21],
            [bS[22]] = bS[23]
        };
        bS[16] = "G\x12\x16\x01G\xcdl\xfcb\x9dm|";
        bS[17] = 4811766040768;
        bS[13] = r15;
        bS[18] = "\xbc\xa3\x1bP\xc3Z\x05\x1e\xbdx+";
        bS[14] = r16;
        bS[27] = 8592953577377;
        bS[15] = bS[14](bS[16], bS[17]);
        bS[24] = "\xf6\xcd\\b\x0f<\x05";
        bS[22] = "yXF";
        bS[20] = 148039794756;
        bS[12] = bS[13][bS[15]];
        bS[19] = 356844306598;
        bS[15] = r15;
        bS[23] = 35021370490804;
        bS[16] = r16;
        bS[17] = bS[16](bS[18], bS[19]);
        bS[19] = "\xde\x02\x82\xe8\xba\xf7B\xfeH{\xd8\x11[r\x19\x1c\xd0\xa8\x8b\xc8\xc6\xca.\xe9Z\x97\xa8";
        bS[14] = bS[15][bS[17]];
        bS[25] = 12074588526070;
        bS[16] = r15;
        bS[17] = r16;
        bS[21] = 24619837222088;
        bS[18] = bS[17](bS[19], bS[20]);
        bS[20] = "d\xa2\xdbU\xbe";
        bS[15] = bS[16][bS[18]];
        bS[17] = r15;
        bS[18] = r16;
        bS[19] = bS[18](bS[20], bS[21]);
        bS[16] = bS[17][bS[19]];
        bS[19] = r15;
        bS[20] = r16;
        bS[17] = .1;
        bS[21] = bS[20](bS[22], bS[23]);
        bS[18] = bS[19][bS[21]];
        bS[19] = 3;
        bS[21] = r15;
        bS[22] = r16;
        bS[23] = bS[22](bS[24], bS[25]);
        bS[20] = bS[21][bS[23]];
        bS[23] = r15;
        bS[24] = r16;
        bS[21] = true;
        bS[25] = bS[24](bS[26], bS[27]);
        bS[22] = bS[23][bS[25]];
        bS[25] = r15;
        bS[26] = r16;
        bS[27] = bS[26](bS[28], bS[29]);
        bS[23] = .3;
        bS[28] = "V\x0f\xcc\xb6@\xdf\xed\xf3\x9b\x8d\xad<O";
        bS[24] = bS[25][bS[27]];
        bS[25] = true;
        bS[13] = {
            [bS[14]] = bS[15],
            [bS[16]] = bS[17],
            [bS[18]] = bS[19],
            [bS[20]] = bS[21],
            [bS[22]] = bS[23],
            [bS[24]] = bS[25]
        };
        bS[15] = r15;
        bS[18] = "L1!\xe6{\x00\x94\x10=\x85\xb6T\xb7\x1e";
        bS[23] = 26923683311865;
        bS[21] = 8969416118352;
        bS[19] = 28259548574567;
        bS[25] = 32903744060378;
        bS[16] = r16;
        bS[27] = 31713376647599;
        bS[17] = bS[16](bS[18], bS[19]);
        bS[24] = "Auj";
        bS[20] = "\t\xe1#\x86\xbd\xaah\xcf\x96\xd5\x90";
        bS[14] = bS[15][bS[17]];
        bS[17] = r15;
        bS[18] = r16;
        bS[19] = bS[18](bS[20], bS[21]);
        bS[21] = "\xb2X\x08\xed\x00\"\xed\x186\xfb\xf3\xbf\xd5\xfd\xcb\xe5n<\xf5\xc1U1\xb3\xf4d\xd0R";
        bS[16] = bS[17][bS[19]];
        bS[22] = 35104985432027;
        bS[18] = r15;
        bS[19] = r16;
        bS[20] = bS[19](bS[21], bS[22]);
        bS[17] = bS[18][bS[20]];
        bS[19] = r15;
        bS[20] = r16;
        bS[22] = "@}\xe3A\xf7";
        bS[21] = bS[20](bS[22], bS[23]);
        bS[18] = bS[19][bS[21]];
        bS[21] = r15;
        bS[22] = r16;
        bS[29] = 22461682510043;
        bS[23] = bS[22](bS[24], bS[25]);
        bS[20] = bS[21][bS[23]];
        bS[21] = 3;
        bS[19] = 1.6;
        bS[23] = r15;
        bS[24] = r16;
        bS[26] = "\x94\xf3i\x05\x99\xce\x9b";
        bS[25] = bS[24](bS[26], bS[27]);
        bS[22] = bS[23][bS[25]];
        bS[23] = true;
        bS[25] = r15;
        bS[26] = r16;
        bS[27] = bS[26](bS[28], bS[29]);
        bS[24] = bS[25][bS[27]];
        bS[27] = r15;
        bS[25] = 1;
        bS[28] = r16;
        bS[29] = bS[28](bS[30], bS[31]);
        bS[26] = bS[27][bS[29]];
        bS[27] = true;
        bS[15] = {
            [bS[16]] = bS[17],
            [bS[18]] = bS[19],
            [bS[20]] = bS[21],
            [bS[22]] = bS[23],
            [bS[24]] = bS[25],
            [bS[26]] = bS[27]
        };
        bS[21] = 19943550280774;
        bS[17] = r15;
        bS[18] = r16;
        bS[22] = "\xa6\x06R\xc4\x12\x07\xf0\xb4\xe3i'";
        bS[23] = 34789267291976;
        bS[20] = "p'\xc1.";
        bS[19] = bS[18](bS[20], bS[21]);
        bS[26] = "(,\xf2";
        bS[16] = bS[17][bS[19]];
        bS[19] = r15;
        bS[30] = "\x91Zfj\xfcm\xd9\xb3FEU\xba\x86";
        bS[20] = r16;
        bS[25] = 34305933327;
        bS[24] = 23228167973440;
        bS[21] = bS[20](bS[22], bS[23]);
        bS[18] = bS[19][bS[21]];
        bS[29] = 28786357007452;
        bS[27] = 7028267945160;
        bS[20] = r15;
        bS[21] = r16;
        bS[28] = "F\x17\xd6\xff\x1f\x99!";
        bS[23] = "K\xcd\x13\x1d\xc5/\x9b#1\xf0mw\x12l\xf17\x82d\\R\x9c\x8e";
        bS[22] = bS[21](bS[23], bS[24]);
        bS[19] = bS[20][bS[22]];
        bS[24] = "L\x9b\xa1\xa0\x12";
        bS[21] = r15;
        bS[22] = r16;
        bS[23] = bS[22](bS[24], bS[25]);
        bS[20] = bS[21][bS[23]];
        bS[21] = .2;
        bS[31] = 2991045297520;
        bS[23] = r15;
        bS[24] = r16;
        bS[25] = bS[24](bS[26], bS[27]);
        bS[22] = bS[23][bS[25]];
        bS[25] = r15;
        bS[23] = 1.8;
        bS[26] = r16;
        bS[27] = bS[26](bS[28], bS[29]);
        bS[24] = bS[25][bS[27]];
        bS[27] = r15;
        bS[25] = true;
        bS[28] = r16;
        bS[29] = bS[28](bS[30], bS[31]);
        bS[26] = bS[27][bS[29]];
        bS[27] = 1;
        bS[29] = r15;
        bS[30] = r16;
        bS[31] = bS[30](bS[32], bS[33]);
        bS[33] = 10967811675123;
        bS[28] = bS[29][bS[31]];
        bS[29] = true;
        bS[17] = {
            [bS[18]] = bS[19],
            [bS[20]] = bS[21],
            [bS[22]] = bS[23],
            [bS[24]] = bS[25],
            [bS[26]] = bS[27],
            [bS[28]] = bS[29]
        };
        bS[19] = r15;
        bS[26] = 16639752756804;
        bS[29] = 19575199294363;
        bS[22] = "\x7f\xe1vM\x0f";
        bS[35] = 24386965351516;
        bS[20] = r16;
        bS[23] = 1276920545874;
        bS[21] = bS[20](bS[22], bS[23]);
        bS[24] = "\x00\n\xd2%?`\xd3u\xb6\xc5I";
        bS[18] = bS[19][bS[21]];
        bS[21] = r15;
        bS[28] = ">02";
        bS[22] = r16;
        bS[25] = 2913962591564;
        bS[23] = bS[22](bS[24], bS[25]);
        bS[20] = bS[21][bS[23]];
        bS[27] = 10891978593231;
        bS[25] = "\x0e,\xa5\x02V\x07\x18\x07\x9c4\x0c\xe5\xc74\xeaM\xe0\xbfx\x10\xd8\x9b\xd0BO\xf4 ";
        bS[30] = "B\xf5'#\xb0\xa9\x14";
        bS[22] = r15;
        bS[23] = r16;
        bS[24] = bS[23](bS[25], bS[26]);
        bS[26] = "\x9bUZ/\xf7";
        bS[21] = bS[22][bS[24]];
        bS[23] = r15;
        bS[24] = r16;
        bS[25] = bS[24](bS[26], bS[27]);
        bS[22] = bS[23][bS[25]];
        bS[25] = r15;
        bS[32] = "\x85\x1b\xa9\x9a\x80\xa7*\xa5~\x0c\xf5Y\x82";
        bS[23] = 2;
        bS[26] = r16;
        bS[27] = bS[26](bS[28], bS[29]);
        bS[31] = 17436100321207;
        bS[24] = bS[25][bS[27]];
        bS[27] = r15;
        bS[28] = r16;
        bS[29] = bS[28](bS[30], bS[31]);
        bS[26] = bS[27][bS[29]];
        bS[27] = true;
        bS[25] = 2.2;
        bS[29] = r15;
        bS[30] = r16;
        bS[31] = bS[30](bS[32], bS[33]);
        bS[28] = bS[29][bS[31]];
        bS[29] = 1.2;
        bS[31] = r15;
        bS[32] = r16;
        bS[33] = bS[32](bS[34], bS[35]);
        bS[30] = bS[31][bS[33]];
        bS[34] = "\x91\xd6~\x8b\x993jK\x88%\xfaoI";
        bS[31] = true;
        bS[19] = {
            [bS[20]] = bS[21],
            [bS[22]] = bS[23],
            [bS[24]] = bS[25],
            [bS[26]] = bS[27],
            [bS[28]] = bS[29],
            [bS[30]] = bS[31]
        };
        bS[21] = r15;
        bS[30] = "_(\xd6";
        bS[25] = 17792944644189;
        bS[24] = "\xe9\x8e:\x00\xa7";
        bS[22] = r16;
        bS[27] = 11115851469880;
        bS[35] = 11358347121833;
        bS[29] = 17629943029777;
        bS[26] = "5\xc1y\x8e\x19{K{\xf0,[";
        bS[23] = bS[22](bS[24], bS[25]);
        bS[20] = bS[21][bS[23]];
        bS[23] = r15;
        bS[24] = r16;
        bS[25] = bS[24](bS[26], bS[27]);
        bS[28] = 13822430468388;
        bS[31] = 23190439995950;
        bS[27] = "\x1c8X4I*\xbd\x8a#\xa3\xb0\xea{/\x04\xf3\x90r\x82\xc5\xa3\xa9Z\xb3\x8d\xec\xe8";
        bS[22] = bS[23][bS[25]];
        bS[24] = r15;
        bS[25] = r16;
        bS[32] = ")\xc0|1\xff\xf0\xa0";
        bS[26] = bS[25](bS[27], bS[28]);
        bS[23] = bS[24][bS[26]];
        bS[25] = r15;
        bS[28] = "\x9dg%9\xca";
        bS[26] = r16;
        bS[27] = bS[26](bS[28], bS[29]);
        bS[24] = bS[25][bS[27]];
        bS[25] = 0.5;
        bS[27] = r15;
        bS[28] = r16;
        bS[33] = 22415384045765;
        bS[29] = bS[28](bS[30], bS[31]);
        bS[26] = bS[27][bS[29]];
        bS[29] = r15;
        bS[30] = r16;
        bS[27] = 3.5;
        bS[31] = bS[30](bS[32], bS[33]);
        bS[28] = bS[29][bS[31]];
        bS[31] = r15;
        bS[32] = r16;
        bS[29] = true;
        bS[33] = bS[32](bS[34], bS[35]);
        bS[30] = bS[31][bS[33]];
        bS[33] = r15;
        bS[31] = 1.5;
        bS[34] = r16;
        bS[35] = bS[34](bS[36], bS[37]);
        bS[32] = bS[33][bS[35]];
        bS[33] = true;
        bS[21] = {
            [bS[22]] = bS[23],
            [bS[24]] = bS[25],
            [bS[26]] = bS[27],
            [bS[28]] = bS[29],
            [bS[30]] = bS[31],
            [bS[32]] = bS[33]
        };
        r63 = {
            ["DefaultIdle"] = {
                ["AnimationId"] = "rbxassetid://11394033602",
                ["Start"] = 1,
                ["End"] = 1.22,
                ["Reverse"] = true,
                ["PlaybackSpeed"] = .2,
                ["AdjustableSpeed"] = true
            },
            ["ChillLevitate"] = {
                ["AnimationId"] = "rbxassetid://125815409725539",
                ["Start"] = 1,
                ["End"] = 2.6,
                ["Reverse"] = true,
                ["PlaybackSpeed"] = 0.5,
                ["AdjustableSpeed"] = true
            },
            ["FlashyFly"] = {
                ["AnimationId"] = "rbxassetid://83375399295408",
                ["Start"] = .9,
                ["End"] = 1.8,
                ["Reverse"] = true,
                ["PlaybackSpeed"] = .6,
                ["AdjustableSpeed"] = true
            },
            ["MetroMan"] = {
                ["AnimationId"] = "rbxassetid://74645777874912",
                ["Start"] = .1,
                ["End"] = 1.8,
                ["Reverse"] = true,
                ["PlaybackSpeed"] = .7,
                ["AdjustableSpeed"] = true
            },
            ["MustacheMark"] = {
                ["AnimationId"] = "rbxassetid://77807262438365",
                ["Start"] = .1,
                ["End"] = 3,
                ["Reverse"] = true,
                ["PlaybackSpeed"] = 1,
                ["AdjustableSpeed"] = true
            },
            ["ZombieMark"] = {
                ["AnimationId"] = "rbxassetid://75532269733454",
                ["Start"] = .1,
                ["End"] = 3,
                ["Reverse"] = true,
                ["PlaybackSpeed"] = 1,
                ["AdjustableSpeed"] = true
            },
            ["RelaxedFly"] = {
                ["AnimationId"] = "rbxassetid://132783162476851",
                ["Start"] = .1,
                ["End"] = 5,
                ["Reverse"] = true,
                ["PlaybackSpeed"] = 1,
                ["AdjustableSpeed"] = true
            },
            ["TrackSuitMark"] = {
                ["AnimationId"] = "rbxassetid://125313210961391",
                ["Start"] = .1,
                ["End"] = 4,
                ["Reverse"] = true,
                ["PlaybackSpeed"] = 1,
                ["AdjustableSpeed"] = true
            },
            ["LongHairMark"] = {
                ["AnimationId"] = "rbxassetid://101003076314239",
                ["Start"] = .1,
                ["End"] = 4,
                ["Reverse"] = true,
                ["PlaybackSpeed"] = 1,
                ["AdjustableSpeed"] = true
            },
            ["FlaxanMark"] = {
                ["AnimationId"] = "rbxassetid://108933593456838",
                ["Start"] = .1,
                ["End"] = 4,
                ["Reverse"] = true,
                ["PlaybackSpeed"] = 1,
                ["AdjustableSpeed"] = true
            },
            ["MasklessMark"] = {
                ["AnimationId"] = "rbxassetid://72952994235315",
                ["Start"] = .1,
                ["End"] = 4,
                ["Reverse"] = true,
                ["PlaybackSpeed"] = 1,
                ["AdjustableSpeed"] = true
            },
            ["ViltrimiteMark"] = {
                ["AnimationId"] = "rbxassetid://124574039035034",
                ["Start"] = .1,
                ["End"] = 5,
                ["Reverse"] = true,
                ["PlaybackSpeed"] = 1,
                ["AdjustableSpeed"] = true
            },
            ["PrisonerMark"] = {
                ["AnimationId"] = "rbxassetid://98385196315632",
                ["Start"] = 1,
                ["End"] = 4,
                ["Reverse"] = true,
                ["PlaybackSpeed"] = .6,
                ["AdjustableSpeed"] = true
            },
            ["TargetMark"] = {
                ["AnimationId"] = "rbxassetid://122741335712327",
                ["Start"] = 1,
                ["End"] = 5.5,
                ["Reverse"] = true,
                ["PlaybackSpeed"] = .6,
                ["AdjustableSpeed"] = true
            },
            ["NoGoggles"] = {
                ["AnimationId"] = "rbxassetid://77715558557237",
                ["Start"] = 1,
                ["End"] = 5,
                ["Reverse"] = true,
                ["PlaybackSpeed"] = .7,
                ["AdjustableSpeed"] = true
            },
            ["SheistyMark"] = {
                ["AnimationId"] = "rbxassetid://121605966423204",
                ["Start"] = 1,
                ["End"] = 3.9,
                ["Reverse"] = true,
                ["PlaybackSpeed"] = .6,
                ["AdjustableSpeed"] = true
            },
            ["AnnoyedIdle"] = {
                ["AnimationId"] = "rbxassetid://93326430026112",
                ["Start"] = .2,
                ["End"] = 3,
                ["Reverse"] = true,
                ["PlaybackSpeed"] = 1.2,
                [r15[r16("\x8f1b\x04'fu'\xec7 \x92\x88\xd7\x86", bS[1])]] = true
            },
            ["UpsideDown"] = {
                ["AnimationId"] = "rbxassetid://100566641677826",
                ["Start"] = .1,
                ["End"] = 3,
                ["Reverse"] = true,
                [r15[r16("<\x9b\x8a\x88\x15\xbc\x14\xb2=\xf2\xdc;\xd6", bS[1])]] = 1,
                [r15[bS[1]]] = true
            },
            ["Conquest"] = {
                ["AnimationId"] = "rbxassetid://91850736796162",
                ["Start"] = 0.5,
                ["End"] = 2.5,
                [r15[r16("T\xd2S$\xc3\xa5\xe7", bS[1])]] = true,
                [r15[bS[1]]] = .7,
                [bS[1][bS[3]]] = bS[1]
            },
            ["MohawkMark"] = {
                ["AnimationId"] = "rbxassetid://116733977004098",
                ["Start"] = 0.5,
                [r15[r16("\xcaTE", bS[1])]] = 3.5,
                [r15[bS[1]]] = true,
                [bS[1][bS[3]]] = bS[1],
                [bS[2]] = bS[3]
            },
            ["BulletProofMark"] = {
                ["AnimationId"] = "rbxassetid://95218435498795",
                [r15[r16("\x11\xf4\xfc)\xc8", bS[1])]] = 0.5,
                [r15[bS[1]]] = 3.5,
                [bS[1][bS[3]]] = bS[1],
                [bS[2]] = bS[3],
                [bS[4]] = bS[5]
            },
            ["Sinisterv3"] = {
                [r15[r16("\x04\xcfCb_\x80:\xc1}$\x1c", bS[1])]] = r15[r16(bS[1], bS[2])],
                [r15[bS[1]]] = 0.5,
                [bS[1][bS[3]]] = bS[1],
                [bS[2]] = bS[3],
                [bS[4]] = bS[5],
                [bS[6]] = bS[7]
            },
            [r15[r16("D>\xec\x91D\xfftQ", bS[1])]] = {
                [r15[bS[1]]] = r15[bS[2]],
                [bS[1][bS[3]]] = bS[1],
                [bS[2]] = bS[3],
                [bS[4]] = bS[5],
                [bS[6]] = bS[7],
                [bS[8]] = bS[9]
            },
            [r15[bS[1]]] = {
                [bS[1][bS[3]]] = bS[1],
                [bS[2]] = bS[3],
                [bS[4]] = bS[5],
                [bS[6]] = bS[7],
                [bS[8]] = bS[9],
                [bS[10]] = bS[11]
            },
            [bS[1][bS[3]]] = bS[1],
            [bS[2]] = bS[3],
            [bS[4]] = bS[5],
            [bS[6]] = bS[7],
            [bS[8]] = bS[9],
            [bS[10]] = bS[11],
            [bS[12]] = bS[13],
            [bS[14]] = bS[15],
            [bS[16]] = bS[17],
            [bS[18]] = bS[19],
            [bS[20]] = bS[21]
        };
        bS[12] = function(arg1_2, ...)
            if not workspace.CurrentCamera then
                return;
            end;
            r56 = r56 + (r57 - r56) * math.min(r58 * arg1_2, 1);
            workspace.CurrentCamera.FieldOfView = r56;
            return; 
        end;
        r64 = "DefaultIdle";
        r65 = Instance.new("Animation");
        bS[17] = function(arg1_3, ...)
            r66 = arg1_3;
            v8 = r67;
            if v8 then
                v8 = r67;
                v8.Disconnect(v8);
            end;
            r68 = r66.Position.Y;
            r69 = 0;
            v8 = r24.Heartbeat;
            r67 = v8.Connect(v8, function(arg1_4, ...)
                if not r38 or (not r66 or not r66.Parent) then
                    return;
                end;
                r69 = r69 + arg1_4 * r52;
                N = r66.CFrame;
                r66.CFrame = CFrame.new(N.X, r68 + math.sin(r69) * r51, N.v1) * N.Rotation;
                return; 
            end);
            return; 
        end;
        r70 = Instance.new("Animation");
        bS[13] = function(...)
            if r40 == 1 then
                r57 = r54;
            else
                if r40 == 2 then
                    r57 = r54 + 5;
                else
                    if r40 == 3 then
                        r57 = r55;
                    else
                        r57 = r53;
                    end;
                    return;
                end;
            end; 
        end;
        r71 = Instance.new("Animation");
        r72 = Instance.new("Animation");
        r73 = 75;
        bS[2] = 91;
        r74 = 70;
        local function r75(...)
            r65.AnimationId = r63.Move.AnimationId;
            r70.AnimationId = r63.Boost.AnimationId;
            r71.AnimationId = r63.Ultra.AnimationId;
            r72.AnimationId = r63[r64].AnimationId;
            return; 
        end;
        r75();
        r76 = 45;
        r77 = 1;
        r78 = .92;
        r79 = .15;
        bS[7] = 94;
        r80 = .85;
        r81 = .7;
        local function r82(arg1_5, ...)
            r83 = arg1_5;
            return pcall(function(...)
                return readfile(r83); 
            end); 
        end;
        local function r84(...)
            if r82(r44) then
                N = {
                    pcall(function(...)
                        v8 = r28;
                        return v8.JSONDecode(v8, readfile(r44)); 
                    end)
                };
                v1 = N[2];
                S = pcall(function(...)
                    v8 = r28;
                    return v8.JSONDecode(v8, readfile(r44)); 
                end);
                if S then
                    v3 = N[2];
                end;
                if S then
                    v4 = pairs;
                    P = v1.Keybinds or ;
                    q = v4[3];
                    N = v4[2];
                    for q, v2 in v4(v3) do
                        r85 = v2;
                        v2 = 179;
                        if r42[q] then
                            v8 = pcall;
                            r = {
                                v8(function(...)
                                    return Enum.KeyCode[r85]; 
                                end)
                            };
                            K = r[2];
                            c = v8(function(...)
                                return Enum.KeyCode[r85]; 
                            end);
                            if c then
                                v6 = r[2];
                            end;
                            if c then
                                v8 = r[2];
                                v7 = K;
                            else
                                t = Enum.KeyCode;
                                v10 = t[3];
                                for v10, t in t[1], pairs(t.GetEnumItems(t)) do
                                    v6 = v10;
                                    if tostring(t) == r85 then
                                        v7 = t;
                                    else
                                        
                                    end; 
                                end;
                                if nil then
                                    o[mL][q] = nil;
                                end;
                            end;
                        end; 
                    end;
                    if v1.SpeedMultipliers then
                        q = v4;
                        r33 = v1.SpeedMultipliers.BaseSpeed or 1;
                        P = v4;
                        v4 = v4;
                        r34 = v1.SpeedMultipliers.Boost1 or 1;
                        r35 = v1.SpeedMultipliers.Boost2 or 1;
                        v2 = v4;
                        r36 = v1.SpeedMultipliers.Boost3 or 1;
                    end;
                    if v1.HoverSettings then
                        r51 = v1.HoverSettings.Height or r49;
                        r52 = v1.HoverSettings.Speed or r50;
                        v8 = v4;
                    end;
                    if v1.ShowArms ~= nil then
                        r37 = N[2].ShowArms;
                    end;
                    if v1.CurrentIdle then
                        r64 = N[2].CurrentIdle;
                        r75();
                        task.spawn(function(...)
                            task.wait(1);
                            if animationScrollingFrame then
                                N = animationScrollingFrame;
                                v1 = N[2];
                                N = N[1];
                                for S, P in pairs(N.GetChildren(N)) do
                                    q = S;
                                    if P.IsA(P, "TextButton") then
                                        v2 = r15;
                                        if P.FindFirstChild(P, "SelectionIndicator") then
                                            v2 = P.Name == r64;
                                            v8 = "BackgroundColor3";
                                            c = v8;
                                            if v2 then
                                                K = Color3.fromRGB(180, 130, 230);
                                            end;
                                            v7 = v2;
                                            v8 = v8;
                                            if v2 then
                                                v8 = r16;
                                                v8[v8] = K;
                                                v8 = "Size";
                                                if v2 then
                                                    K = UDim2.new(.03, 0, .6, 0);
                                                end;
                                                v8 = v8;
                                                if v2 then
                                                    v8 = v8;
                                                    v4[v8] = v2;
                                                else
                                                    v7 = UDim2.new(.02, 0, .4, 0);
                                                end;
                                            else
                                                v7 = Color3.fromRGB(80, 50, 100);
                                            end;
                                        end;
                                    end; 
                                end;
                            end;
                            return; 
                        end);
                    end;
                    return true;
                end;
            end;
            return false; 
        end;
        local function r86(...)
            P = r15;
            v4 = "Height";
            v2 = r51;
            v7 = "Speed";
            c = r52;
            v2 = r37;
            r87 = {
                ["Keybinds"] = {},
                ["SpeedMultipliers"] = {
                    ["BaseSpeed"] = r33,
                    ["Boost1"] = r34,
                    ["Boost2"] = r35,
                    ["Boost3"] = r36
                },
                ["HoverSettings"] = P,
                ["ShowArms"] = v2,
                ["CurrentIdle"] = r64,
                ["Version"] = "1.147"
            };
            q = r43;
            S = P[2];
            q = P[1];
            for N, v4 in pairs(q), v2 do
                r87.Keybinds[N] = tostring(v4); 
            end;
            pcall(function(...)
                S = r28;
                writefile(r44, S.JSONEncode(S, r87));
                return; 
            end);
            return; 
        end;
        r88 = 0;
        r89 = false;
        r90 = 0;
        bS[1] = 98;
        bS[3] = 101;
        bS[4] = function(...)
            if not o[bS[3]] then
                return;
            end;
            S = pcall(o[bS[3]]);
            if not S then
                warn("Failed to toggle UI: " .. tostring(N[2]));
                task.delay(1, function(...)
                    pcall(initializeScript);
                    return; 
                end);
            end;
            return; 
        end;
        r91 = Vector3.new(0, 0, 0);
        bS[5] = function(...)
            v8 = r29;
            r92 = Instance.new("Frame");
            r92.Name = "PremiumNotification";
            r92.Size = UDim2.new(0, 400, 0, 100);
            r92.Position = UDim2.new(0.5, -200, 0, -120);
            r92.AnchorPoint = Vector2.new(0.5, 0);
            r92.BackgroundColor3 = Color3.fromRGB(15, 8, 25);
            r92.BackgroundTransparency = .15;
            r92.BorderSizePixel = 0;
            r92.ClipsDescendants = true;
            r92.ZIndex = 100;
            N = v8.WaitForChild(v8, "PlayerGui");
            r92.Parent = N;
            S = Instance.new("UICorner");
            S.CornerRadius = UDim.new(0, 20);
            S.Parent = r92;
            N = Instance.new("Frame");
            N.Name = "Border";
            N.Size = UDim2.new(1, 4, 1, 4);
            N.Position = UDim2.new(0, -2, 0, -2);
            N.BackgroundTransparency = 1;
            N.ZIndex = 99;
            N.Parent = r92;
            q = Instance.new("UIGradient");
            q.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 80, 220)),
                ColorSequenceKeypoint.new(.3, Color3.fromRGB(220, 120, 255)),
                ColorSequenceKeypoint.new(.7, Color3.fromRGB(160, 60, 200)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 80, 220))
            });
            q.Rotation = 0;
            q.Parent = N;
            v8 = r27;
            P = v8.Create(v8, q, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
                ["Rotation"] = 360
            });
            P.Play(P);
            v4 = Instance.new("ImageLabel");
            v4.Name = "OuterGlow";
            v4.Size = UDim2.new(1, 40, 1, 40);
            v4.Position = UDim2.new(0, -20, 0, -20);
            v4.BackgroundTransparency = 1;
            v4.Image = "rbxassetid://5028857084";
            v4.ImageColor3 = Color3.fromRGB(100, 40, 150);
            v4.ImageTransparency = .8;
            v4.ScaleType = Enum.ScaleType.Slice;
            v4.SliceCenter = Rect.new(24, 24, 276, 276);
            v4.ZIndex = 98;
            v4.Parent = r92;
            v2 = Instance.new("ImageLabel");
            v2.Name = "InnerGlow";
            v2.Size = UDim2.new(1, 25, 1, 25);
            v2.Position = UDim2.new(0, -12.5, 0, -12.5);
            v2.BackgroundTransparency = 1;
            v2.Image = "rbxassetid://5028857084";
            v2.ImageColor3 = Color3.fromRGB(160, 80, 220);
            v2.ImageTransparency = .6;
            v2.ScaleType = Enum.ScaleType.Slice;
            v2.SliceCenter = Rect.new(24, 24, 276, 276);
            v2.ZIndex = 99;
            v2.Parent = r92;
            v7 = Instance.new("UIGradient");
            v7.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 12, 40)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(35, 18, 55)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 12, 40))
            });
            v7.Rotation = 90;
            v7.Parent = r92;
            v8 = r27;
            c = v8.Create(v8, v7, TweenInfo.new(6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
                ["Rotation"] = 450
            });
            c.Play(c);
            K = Instance.new("ImageLabel");
            K.Name = "Pattern";
            K.Size = UDim2.new(1, 0, 1, 0);
            K.Position = UDim2.new(0, 0, 0, 0);
            K.BackgroundTransparency = 1;
            K.Image = "rbxassetid://8992235943";
            K.ImageColor3 = Color3.fromRGB(120, 60, 180);
            K.ImageTransparency = .9;
            K.ZIndex = 100;
            K.Parent = r92;
            v8 = r27;
            v6 = v8.Create(v8, K, TweenInfo.new(15, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true), {
                ["ImageTransparency"] = .85
            });
            v6.Play(v6);
            r93 = Instance.new("TextLabel");
            r93.Name = "NotificationText";
            r93.Size = UDim2.new(.9, 0, .8, 0);
            r93.Position = UDim2.new(.05, 0, .1, 0);
            r93.BackgroundTransparency = 1;
            r93.Text = "";
            r93.TextColor3 = Color3.fromRGB(255, 255, 255);
            r93.TextSize = 18;
            r93.Font = Enum.Font.GothamBold;
            r93.TextWrapped = true;
            r93.ZIndex = 101;
            r93.Parent = r92;
            v9 = Instance.new("UIGradient");
            v9.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(220, 180, 255)),
                ColorSequenceKeypoint.new(.3, Color3.fromRGB(255, 220, 255)),
                ColorSequenceKeypoint.new(.7, Color3.fromRGB(200, 150, 240)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 180, 255))
            });
            v9.Rotation = 0;
            v9.Parent = r93;
            v8 = r27;
            v10 = v8.Create(v8, v9, TweenInfo.new(4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
                ["Rotation"] = 360
            });
            v10.Play(v10);
            t = Instance.new("ImageLabel");
            t.Name = "TextGlow";
            t.Size = UDim2.new(1, 10, 1, 10);
            t.Position = UDim2.new(0, -5, 0, -5);
            t.BackgroundTransparency = 1;
            t.Image = "rbxassetid://5028857084";
            t.ImageColor3 = Color3.fromRGB(200, 150, 240);
            t.ImageTransparency = .8;
            t.ScaleType = Enum.ScaleType.Slice;
            t.SliceCenter = Rect.new(24, 24, 276, 276);
            t.ZIndex = 100;
            t.Parent = r93;
            F = Instance.new("TextLabel");
            F.Name = "LoadingDots";
            F.Size = UDim2.new(.9, 0, .2, 0);
            F.Position = UDim2.new(.05, 0, .7, 0);
            F.BackgroundTransparency = 1;
            F.Text = "";
            F.TextColor3 = Color3.fromRGB(200, 180, 240);
            F.TextSize = 14;
            F.Font = Enum.Font.Gotham;
            F.ZIndex = 101;
            F.Visible = false;
            F.Parent = r92;
            return; 
        end;
        bS[18] = function(...)
            if r67 then
                v8 = r67;
                v8.Disconnect(v8);
            end;
            return; 
        end;
        bS[11] = function(...)
            r38 = false;
            r39 = false;
            r40 = 0;
            r62 = r60;
            r59 = {
                ["F"] = 0,
                ["B"] = 0,
                ["L"] = 0,
                ["R"] = 0
            };
            r56 = r53;
            r57 = r53;
            r89 = false;
            r91 = Vector3.new(0, 0, 0);
            if workspace.CurrentCamera then
                workspace.CurrentCamera.FieldOfView = r53;
            end;
            return; 
        end;
        bS[15] = function(...)
            if r96 then
                pcall(function(...)
                    v8 = r96;
                    v8.Disconnect(v8);
                    return; 
                end);
            end;
            if r94 then
                pcall(function(...)
                    v8 = r94.IsPlaying;
                    if v8 then
                        v8 = r94;
                        v8.Stop(v8, .1);
                    end;
                    return; 
                end);
                pcall(function(...)
                    v8 = o[zL];
                    v8.Destroy(v8);
                    return; 
                end);
            end;
            if r31 then
                pcall(function(...)
                    v8 = r31.IsPlaying;
                    if v8 then
                        v8 = r31;
                        v8.Stop(v8, .1);
                    end;
                    return; 
                end);
                pcall(function(...)
                    v8 = o[v9];
                    v8.Destroy(v8);
                    return; 
                end);
            end;
            r97 = r29.Character;
            if r97 then
                pcall(function(...)
                    N = r97;
                    v1 = N[2];
                    N = N[1];
                    for S, P in pairs(N.GetChildren(N)) do
                        q = S;
                        if P.IsA(P, "Animation") and P.Name == "ReplicatedIdle" then
                            P.Destroy(P);
                        end; 
                    end;
                    return; 
                end);
            end;
            r98 = false;
            return; 
        end;
        r98 = false;
        r104 = false;
        r106 = false;
        r108 = false;
        bS[14] = function(arg1_6, arg2_6, ...)
            if not r108 then
                v8 = r26;
                v8.SetCore(v8, "SendNotification", {
                    ["Title"] = arg1_6,
                    ["Text"] = arg2_6,
                    ["Duration"] = 5
                });
                r108 = true;
            end;
            return; 
        end;
        bS[21] = function(...)
            if r38 then
                if r40 == 0 then
                    r62 = r60 * r33;
                else
                    if r40 == 1 then
                        r62 = r61 * r33 * r34;
                    else
                        if r40 == 2 then
                            r62 = r61 * 2.5 * r33 * r35;
                        else
                            if r40 == 3 then
                                r62 = r61 * 4 * r33 * r36;
                            end;
                            if speedStat then
                                N = "";
                                if name == "BaseSpeed" then
                                    N = string.format("x%.2f", r33);
                                else
                                    if name == "Boost1" then
                                        N = string.format("x%.2f", r34);
                                    else
                                        if name == "Boost2" then
                                            N = string.format("x%.2f", r35);
                                        else
                                            if name == "Boost3" then
                                                N = string.format("x%.2f", r36);
                                            end;
                                            speedStat.Text = "SPEED: " .. math.floor(r62) .. " (" .. "" .. ")";
                                        end;
                                    end;
                                end;
                            end;
                        end;
                    end;
                end;
            end;
            return; 
        end;
        r109 = false;
        r111 = false;
        o[bS[1]] = 0;
        o[bS[2]] = .2;
        o[bS[3]] = function(...)
            warn("UI not initialized yet");
            return; 
        end;
        r112 = bS[4];
        bS[4] = 113;
        bS[8] = function(...)
            if not r92 then
                return;
            end;
            v8 = r110;
            if v8 then
                v8 = r110;
                v8.Cancel(v8);
            end;
            v8 = r27;
            r110 = v8.Create(v8, r92, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                ["Position"] = UDim2.new(0.5, -200, 0, -120)
            });
            v8 = r110;
            v8.Play(v8);
            v8 = r110.Completed;
            v8.Connect(v8, function(...)
                r92.Visible = false;
                r93.Text = "";
                v8 = r92;
                v1 = v8.FindFirstChild(v8, "LoadingDots");
                if v1 then
                    v1.Visible = false;
                    v1.Text = "";
                end;
                r109 = false;
                return; 
            end);
            return; 
        end;
        o[bS[4]] = bS[5];
        bS[5] = 114;
        bS[6] = function(arg1_7, arg2_7, arg3_7, ...)
            r113 = arg1_7;
            r114 = arg2_7;
            r115 = arg3_7;
            if r109 then
                return;
            end;
            if not r92 or not r93 then
                pcall(o[bS[4]]);
            end;
            if not r92 or not r93 then
                return;
            end;
            if r110 then
                pcall(function(...)
                    v8 = r110;
                    v8.Cancel(v8);
                    return; 
                end);
            end;
            r109 = true;
            pcall(function(...)
                r93.Text = r113;
                v8 = r92;
                r116 = v8.FindFirstChild(v8, "LoadingDots");
                v8 = r116;
                if v8 then
                    v8 = r116;
                    N = v8;
                    v8.Visible = r114 or false;
                    if r114 then
                        r117 = 0;
                        v3 = r24.Heartbeat;
                        r118 = v3.Connect(v3, function(...)
                            if not r92 or not r92.Parent then
                                v8 = r118;
                                v8.Disconnect(v8);
                                return;
                            end;
                            r117 = (r117 + 1) % 4;
                            r116.Text = string.rep(".", r117);
                            return; 
                        end);
                        task.spawn(function(...)
                            if r115 then
                                task.wait(r115);
                            end;
                            v8 = r118;
                            if v8 then
                                v8 = r118;
                                v8.Disconnect(v8);
                            end;
                            return; 
                        end);
                    end;
                end;
                r92.Position = UDim2.new(0.5, -200, 0, -120);
                r92.Visible = true;
                N = r92;
                v3 = N;
                if N then
                    v3 = r92.Parent;
                end;
                v8 = v8;
                if v3 then
                    v3 = r27;
                    r110 = v3.Create(v3, r92, TweenInfo.new(.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                        ["Position"] = UDim2.new(0.5, -200, .1, 0)
                    });
                    v3 = r110;
                    v3.Play(v3);
                end;
                return; 
            end);
            if r115 then
                task.spawn(function(...)
                    task.wait(r115);
                    hidePremiumNotification();
                    return; 
                end);
            end;
            return; 
        end;
        o[bS[5]] = bS[6];
        bS[9] = function(...)
            o[bS[5]]("Cannot switch animations while flying!", false, 3);
            return; 
        end;
        bS[6] = function(...)
            if not r92 then
                return;
            end;
            if r110 then
                pcall(function(...)
                    v8 = r110;
                    v8.Cancel(v8);
                    return; 
                end);
            end;
            pcall(function(...)
                if r92 and r92.Parent then
                    v8 = r27;
                    r110 = v8.Create(v8, r92, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                        ["Position"] = UDim2.new(0.5, -200, 0, -120)
                    });
                    v8 = r110;
                    v8.Play(v8);
                    v8 = r110.Completed;
                    v8.Connect(v8, function(...)
                        v8 = r92;
                        if v8 then
                            r92.Visible = false;
                            r93.Text = "";
                            v8 = r92;
                            v1 = v8.FindFirstChild(v8, "LoadingDots");
                            if v1 then
                                v1.Visible = false;
                                v1.Text = "";
                            end;
                        end;
                        r109 = false;
                        return; 
                    end);
                end;
                return; 
            end);
            return; 
        end;
        o[bS[7]] = bS[8];
        bS[8] = 115;
        bS[10] = function(...)
            if not r47 then
                return;
            end;
            if r38 then
                o[bS[8]]();
                return;
            end;
            r47 = false;
            r48 = false;
            pcall(function(...)
                o[bS[5]]("Loading animation..", true, 2);
                return; 
            end);
            task.delay(r46, function(...)
                r47 = true;
                r48 = true;
                pcall(function(...)
                    o[A[9]]();
                    return; 
                end);
                return; 
            end);
            return; 
        end;
        o[bS[8]] = bS[9];
        bS[9] = 116;
        o[bS[9]] = bS[10];
        bS[10] = 117;
        o[bS[10]] = bS[11];
        bS[11] = 118;
        o[bS[11]] = bS[12];
        bS[12] = 119;
        o[bS[12]] = bS[13];
        bS[13] = 120;
        o[bS[13]] = bS[14];
        bS[24] = function(arg1_8, arg2_8, ...)
            r119 = arg1_8;
            S = arg2_8;
            v8 = S.InputBegan;
            v8.Connect(v8, function(arg1_9, ...)
                v1 = arg1_9;
                if v1.UserInputType == Enum.UserInputType.MouseButton1 then
                    r120 = v1.Position;
                    r121 = r119.Position;
                    r106 = true;
                    N = r27;
                    q = N.Create(N, r119, TweenInfo.new(.1), {
                        ["BackgroundTransparency"] = .05
                    });
                    q.Play(q);
                    q = r119;
                    if q == r103 then
                        N = r27;
                        q = N.Create(N, mainInnerGlow, TweenInfo.new(.1), {
                            ["ImageTransparency"] = .2
                        });
                        q.Play(q);
                    else
                        N = r27;
                        q = N.Create(N, r107, TweenInfo.new(.1), {
                            ["BackgroundTransparency"] = .05,
                            ["Size"] = UDim2.new(0, r73 - 2, 0, r74 - 2)
                        });
                        q.Play(q);
                        N = r27;
                        q = N.Create(N, toggleInnerGlow, TweenInfo.new(.1), {
                            ["ImageTransparency"] = .3
                        });
                        q.Play(q);
                    end;
                end;
                return; 
            end);
            v8 = S.InputChanged;
            v8.Connect(v8, function(arg1_10, ...)
                v1 = arg1_10;
                if v1.UserInputType == Enum.UserInputType.MouseMovement and r106 then
                    S = v1.Position - r120;
                    r119.Position = UDim2.new(r121.X.Scale, r121.X.Offset + S.X, r121.Y.Scale, r121.Y.Offset + S.Y);
                end;
                return; 
            end);
            v8 = S.InputEnded;
            v8.Connect(v8, function(arg1_11, ...)
                if arg1_11.UserInputType == Enum.UserInputType.MouseButton1 then
                    r106 = false;
                    v3 = r27;
                    v7 = false;
                    K = false;
                    S = v3.Create(v3, r119, TweenInfo.new(.2), {
                        ["BackgroundTransparency"] = r119 == r103 and .1 or .1
                    });
                    S.Play(S);
                    S = r119;
                    if S == r103 then
                        v3 = r27;
                        S = v3.Create(v3, mainInnerGlow, TweenInfo.new(.2), {
                            ["ImageTransparency"] = 0.5
                        });
                        S.Play(S);
                    else
                        v3 = r27;
                        S = v3.Create(v3, r107, TweenInfo.new(.2), {
                            ["BackgroundTransparency"] = .1,
                            ["Size"] = UDim2.new(0, r73, 0, r74)
                        });
                        S.Play(S);
                        v3 = r27;
                        S = v3.Create(v3, toggleInnerGlow, TweenInfo.new(.2), {
                            ["ImageTransparency"] = .6
                        });
                        S.Play(S);
                    end;
                end;
                return; 
            end);
            return; 
        end;
        bS[14] = 121;
        o[bS[14]] = bS[15];
        bS[16] = function(arg1_12, arg2_12, ...)
            r122 = arg1_12;
            r123 = arg2_12;
            if not r122 or (not nil.IsA(nil, "Humanoid") or not r122.Parent) then
                return;
            end;
            o[bS[14]]();
            if r123 == "Idle" then
                r124 = r63[r64];
                r125 = r72;
            else
                if r123 == "Move" then
                    r124 = r63.Move;
                    r125 = r65;
                else
                    if r123 == "Boost" then
                        r124 = r63.Boost;
                        r125 = r70;
                    else
                        t = ")\x84\xf2\xef\xc2";
                        F = 22583311001876;
                        if r123 == r15[r16(t, F)] then
                            r124 = r63.Ultra;
                            r125 = r71;
                            if not r124 or not r125 then
                                return;
                            end;
                            r32 = r123;
                            r95 = r125;
                            J = {
                                pcall(function(...)
                                    v8 = r122;
                                    return v8.LoadAnimation(v8, r125); 
                                end)
                            };
                            t = J[2];
                            if not pcall(function(...)
                                v8 = r122;
                                return v8.LoadAnimation(v8, r125); 
                            end) or not t then
                                return;
                            end;
                            r94 = t;
                            r94.Looped = false;
                            pcall(function(...)
                                v8 = r94;
                                v8.Play(v8);
                                r94.TimePosition = r124.Start;
                                v8 = r94;
                                v8.AdjustSpeed(v8, r124.PlaybackSpeed);
                                return; 
                            end);
                            F = r123 == "Idle" and r64 == "Sinister2";
                            J = r123 == "Idle" and r64 == "Thragg";
                            G = r123 == "Idle" and r64 == "ViltrimiteMark";
                            v = r123 == "Idle" and r64 == "MustacheMark";
                            s = r123 == "Idle" and r64 == "ZombieMark";
                            k = r123 == "Idle" and r64 == "RelaxedFly";
                            g = r123 == "Idle" and r64 == "AnnoyedIdle";
                            Q = r123 == "Idle" and r64 == "BulletProofMark";
                            h = r123 == "Idle" and r64 == "LongHairMark";
                            z = r123 == "Idle" and r64 == "Sinisterv3";
                            L = r123 == "Idle" and r64 == "MasklessMark";
                            CL = r123 == "Idle" and r64 == "FlaxanMark";
                            Y = "Idle";
                            B = r123 == Y and r64 == "MetroMan";
                            v8 = v3 == P;
                            e = F;
                            y = v8;
                            if F then
                                v8 = v8;
                                y = r122.Parent;
                                Y = v8;
                                if y then
                                    mL = F;
                                end;
                                if y then
                                    AL = y.GetChildren;
                                    EL = {
                                        AL(y)
                                    };
                                    xL = AL[3];
                                    pL = AL[2];
                                    for xL, EL in pairs(x(EL)) do
                                        mL = xL;
                                        v8 = Y;
                                        if EL.IsA(EL, "Animation") and EL.Name == "ReplicatedIdle" then
                                            EL.Destroy(EL);
                                        end; 
                                    end;
                                    if r31 then
                                        pcall(function(...)
                                            v8 = r31.IsPlaying;
                                            if v8 then
                                                v8 = r31;
                                                v8.Stop(v8, .1);
                                            end;
                                            v8 = r31;
                                            v8.Destroy(v8);
                                            return; 
                                        end);
                                        o[v9] = nil;
                                    end;
                                    pL = Instance.new("Animation");
                                    pL.Name = "ReplicatedIdle";
                                    pL.AnimationId = r124.AnimationId;
                                    pL.Parent = y;
                                    Y = r122;
                                    r31 = Y.LoadAnimation(Y, pL);
                                    r31.Looped = true;
                                    Y = r31;
                                    Y.Play(Y);
                                    Y = r31;
                                    Y.AdjustSpeed(Y, r124.PlaybackSpeed);
                                end;
                                r126 = true;
                                v8 = Y;
                                r127 = r123 == "Idle" and r64 == "BasicIdle";
                                r128 = r124.Start;
                                r129 = r124.PlaybackSpeed;
                                Y = r24.Heartbeat;
                                r96 = Y.Connect(Y, function(...)
                                    v1 = not r38;
                                    v3 = v1;
                                    if v1 then
                                    end; 
                                end);
                                return;
                            else
                                Y = v3 == P;
                                if G then
                                    e = G;
                                    v8 = Y;
                                else
                                    xL = v3 == P;
                                    if v then
                                        mL = v;
                                        v8 = xL;
                                    else
                                        AL = v3 == P;
                                        EL = J;
                                        if J then
                                        end;
                                    end;
                                end;
                            end;
                        end;
                        return;
                    end;
                end;
            end; 
        end;
        bS[15] = 122;
        o[bS[15]] = bS[16];
        bS[16] = 123;
        o[bS[16]] = bS[17];
        bS[17] = 124;
        o[bS[17]] = bS[18];
        bS[18] = 125;
        bS[19] = function(arg1_13, ...)
            if r40 > 0 then
                r40 = 0;
                r62 = r60 * r33;
                o[bS[12]]();
                v8 = 0;
                if r38 and arg1_13 then
                    o[bS[15]](arg1_13, "Idle");
                end;
            end;
            return; 
        end;
        bS[20] = function(arg1_14, ...)
            v1 = arg1_14;
            S = not r38;
            v3 = S;
            if S then
            end; 
        end;
        o[bS[18]] = bS[19];
        bS[22] = function(...)
            if not r38 then
                return;
            end;
            r130 = r29.Character;
            v8 = r130;
            if v8 then
                v8 = r130;
                if v8.FindFirstChild(v8, "HumanoidRootPart") then
                    pcall(function(...)
                        v8 = r130.HumanoidRootPart;
                        if v8.FindFirstChild(v8, "FlightVelocity") then
                            v8 = r130.HumanoidRootPart.FlightVelocity;
                            v8.Destroy(v8);
                        end;
                        return; 
                    end);
                    pcall(function(...)
                        v8 = r130.HumanoidRootPart;
                        if v8.FindFirstChild(v8, "FlightGyro") then
                            v8 = r130.HumanoidRootPart.FlightGyro;
                            v8.Destroy(v8);
                        end;
                        return; 
                    end);
                end;
                v8 = r130;
                if v8.FindFirstChild(v8, "Humanoid") then
                    pcall(function(...)
                        r130.Humanoid.PlatformStand = false;
                        r130.Humanoid.AutoRotate = true;
                        return; 
                    end);
                end;
            end;
            if r99 then
                pcall(function(...)
                    v8 = o[hL];
                    v8.Disconnect(v8);
                    return; 
                end);
            end;
            if r100 then
                pcall(function(...)
                    v8 = o[LL];
                    v8.Disconnect(v8);
                    return; 
                end);
            end;
            if r102 then
                pcall(function(...)
                    v8 = o[BL];
                    v8.Disconnect(v8);
                    return; 
                end);
            end;
            o[bS[17]]();
            o[bS[14]]();
            o[bS[10]]();
            return; 
        end;
        bS[19] = 126;
        o[bS[19]] = bS[20];
        bS[20] = 127;
        o[bS[20]] = bS[21];
        bS[21] = 128;
        o[bS[21]] = bS[22];
        bS[22] = 129;
        bS[23] = function(arg1_15, arg2_15, ...)
            r131 = arg1_15;
            r132 = arg2_15;
            if r38 or (not r131 or not r132) then
                return;
            end;
            if not r48 then
                return;
            end;
            r38 = true;
            r62 = r60 * r33;
            r40 = 0;
            r88 = os.clock();
            r57 = r53;
            r56 = r53;
            r131.PlatformStand = true;
            r131.AutoRotate = false;
            r133 = Instance.new("BodyVelocity");
            r133.Name = "FlightVelocity";
            r133.Parent = r132;
            r133.MaxForce = Vector3.new(9000000000, 9000000000, 9000000000);
            r133.Velocity = Vector3.new(0, 0, 0);
            r134 = Instance.new("BodyGyro");
            r134.Name = "FlightGyro";
            r134.Parent = r132;
            r134.MaxTorque = Vector3.new(9000000000, 9000000000, 9000000000);
            r134.P = 10000;
            r134.D = 500;
            c = r29.CharacterAdded;
            r135 = c.Connect(c, function(arg1_16, ...)
                v1 = arg1_16;
                o[bS[21]]();
                S = v1.WaitForChild(v1, "Humanoid");
                v8 = r30;
                if v8 then
                    v8 = r30;
                    v8.Disconnect(v8);
                end;
                v8 = S.Died;
                r30 = v8.Connect(v8, function(...)
                    o[A[14]]();
                    return; 
                end);
                if r38 then
                    task.wait(0.5);
                    o[bS[22]](S, v1.WaitForChild(v1, "HumanoidRootPart"));
                end;
                return; 
            end);
            c = r99;
            if c then
                c = r99;
                c.Disconnect(c);
            end;
            c = r100;
            if c then
                c = r100;
                c.Disconnect(c);
            end;
            c = r25.InputBegan;
            r99 = c.Connect(c, function(arg1_17, arg2_17, ...)
                v1 = arg1_17;
                if arg2_17 then
                    return;
                end;
                if v1.UserInputType == Enum.UserInputType.Keyboard then
                    N = v1.KeyCode;
                    if N == r43.FlyForward then
                        r59.F = 1 * r41;
                        r88 = os.clock();
                    end;
                    if N == r43.FlyBackward then
                        r59.B = -1 * r41;
                        r88 = os.clock();
                    end;
                    if N == r43.FlyLeft then
                        r59.L = -1;
                        r88 = os.clock();
                    end;
                    if N == r43.FlyRight then
                        r59.v6 = 1;
                        r88 = os.clock();
                    end;
                    if N == r43.CycleBoost then
                        o[bS[19]](r131);
                    end;
                    if N == r43.OpenUI then
                        pcall(function(...)
                            o[A[24]]();
                            return; 
                        end);
                    end;
                end;
                return; 
            end);
            c = r25.InputEnded;
            r100 = c.Connect(c, function(arg1_18, arg2_18, ...)
                v1 = arg1_18;
                if arg2_18 then
                    return;
                end;
                if v1.UserInputType == Enum.UserInputType.Keyboard then
                    N = v1.KeyCode;
                    if N == r43.FlyForward then
                        r59.F = 0;
                    end;
                    if N == r43.FlyBackward then
                        r59.B = 0;
                    end;
                    if N == r43.FlyLeft then
                        r59.L = 0;
                    end;
                    if N == r43.FlyRight then
                        r59.v6 = 0;
                    end;
                end;
                return; 
            end);
            o[bS[16]](r132);
            o[bS[15]](r131, "Idle");
            c = r24.RenderStepped;
            r102 = c.Connect(c, function(arg1_19, ...)
                v1 = arg1_19;
                if not r38 or (not r132 or not r132.Parent) then
                    v8 = r102;
                    if v8 then
                        v8 = r43;
                        v8.Disconnect(v8);
                    end;
                    return;
                end;
                v8 = r24.Heartbeat;
                o[bS[11]](v8.Wait(v8));
                r39 = math.abs(r59.F) > 0 or (math.abs(r59.B) > 0 or (math.abs(r59.L) > 0 or math.abs(r59.v6) > 0));
                P = workspace;
                v4 = "CurrentCamera";
                q = P[v4];
                if q then
                    if not q then
                        task.wait(1);
                        return;
                    end;
                    P = r59.L ~= 0 or r59.v6 ~= 0;
                    if P then
                        v4 = not (r59.F ~= 0);
                    end;
                    if P then
                        o[bS[18]](r131);
                    end;
                    v4 = q.CFrame;
                    K = r132.Position;
                    CFrame.new(r132.Position, K + v4.LookVector);
                    if r39 then
                        o[bS[17]]();
                        r88 = os.clock();
                        K = v4.VectorToWorldSpace(v4, Vector3.new(r59.L + r59.v6, 0, r59.F + r59.B));
                        r = 1;
                        if r40 == r then
                            r = r134.CFrame;
                            r134.CFrame = r.Lerp(r, CFrame.new(v7, c) * CFrame.Angles(math.rad(-90), 0, 0), r79);
                        else
                            r = r134.CFrame;
                            r134.CFrame = r.Lerp(r, CFrame.new(v7, c), r79);
                        end;
                        if K.Magnitude > 0 then
                            v6 = K.Unit * r62;
                            r = r133.Velocity;
                            if r.Magnitude > 5 then
                                J = r.Unit;
                                v8 = K.Unit * r62;
                                if not r89 and math.deg(math.acos(J.Dot(J, v6.Unit))) > r76 then
                                    r89 = true;
                                    r90 = os.clock();
                                    r91 = r133.Velocity.Unit;
                                end;
                                if r89 then
                                    k = r15;
                                    J = os.clock() - r90;
                                    if J < r77 then
                                        v = math.clamp(1 - J / r77, .1, 1);
                                        v6 = r91 * r62 * v + v8 * (1 - v);
                                        k = r91;
                                        v6 = v6 * r78;
                                        r91 = k.Lerp(k, v6.Unit, .1);
                                    else
                                        o[A[34]] = false;
                                    end;
                                else
                                    r.Lerp(r, v8, o[A[40]]);
                                end;
                            else
                                o[A[34]] = false;
                                v6 = v8;
                            end;
                            v6 = v6 * r80;
                        else
                            v6 = Vector3.zero;
                            r89 = false;
                        end;
                        z = r25;
                        L = z.IsKeyDown(z, r43.Ascend);
                        if L then
                            v6 = nil + Vector3.new(0, r62, 0);
                        else
                            L = r25;
                            if L.IsKeyDown(L, r43.Descend) then
                                v6 = nil + Vector3.new(0, -r62, 0);
                            end;
                            r133.Velocity = nil;
                        end;
                    else
                        if not r67 then
                            o[bS[16]](r132);
                        end;
                        v6 = r134.CFrame;
                        r134.CFrame = v6.Lerp(v6, CFrame.new(v7, c), r79);
                        r133.Velocity = Vector3.new(0, 0, 0);
                        o[bS[18]](r131);
                        r89 = false;
                        return;
                    end;
                else
                    q = workspace;
                    N = q.FindFirstChildOfClass(q, "Camera");
                end; 
            end);
            return function(...)
                v8 = r135;
                if v8 then
                    v8 = r135;
                    v8.Disconnect(v8);
                end;
                v8 = r102;
                if v8 then
                    v8 = r102;
                    v8.Disconnect(v8);
                end;
                o[bS[21]]();
                return; 
            end; 
        end;
        o[bS[22]] = bS[23];
        bS[27] = function(...)
            v1 = r29.Character;
            v8 = not v1;
            if v8 then
                v8 = r29.CharacterAdded;
                v1 = v8.Wait(v8);
            end;
            r136 = v1.WaitForChild(v1, "Humanoid");
            r137 = v1.WaitForChild(v1, "HumanoidRootPart");
            v8 = r101;
            if v8 then
                v8 = r101;
                v8.Disconnect(v8);
            end;
            v8 = r25.InputBegan;
            r101 = v8.Connect(v8, function(arg1_20, arg2_20, ...)
                v1 = arg1_20;
                if arg2_20 then
                    return;
                end;
                if v1.UserInputType == Enum.UserInputType.Keyboard then
                    if v1.KeyCode == r43.ToggleFlight then
                        if not r48 then
                            pcall(function(...)
                                o[bS[5]]("Please wait...", false, 1);
                                return; 
                            end);
                            return;
                        end;
                        if r38 then
                            r137();
                        else
                            o[bS[22]](r136, r137);
                        end;
                    else
                        if v1.KeyCode == r43.OpenUI then
                            pcall(function(...)
                                o[A[12]]();
                                return; 
                            end);
                        end;
                    end;
                end;
                return; 
            end);
            v6 = tostring(r43.ToggleFlight);
            J = tostring(r43.CycleBoost);
            Q = tostring(r43.OpenUI);
            o[bS[13]]("Flight Controls", "Press [" .. v6.gsub(v6, "Enum.KeyCode.", "") .. "] to toggle flight\n" .. "Press [" .. J.gsub(J, "Enum.KeyCode.", "") .. "] to cycle boosts\n" .. "Press [" .. Q.gsub(Q, "Enum.KeyCode.", "") .. "] to open animation menu");
            v8 = r136.Died;
            r30 = v8.Connect(v8, function(...)
                o[bS[21]]();
                v8 = r29.CharacterAdded;
                v1 = v8.Wait(v8);
                S = v1.WaitForChild(v1, "Humanoid");
                v8 = r30;
                v8.Disconnect(v8);
                v8 = S.Died;
                r30 = v8.Connect(v8, function(...)
                    o[A[10]]();
                    return; 
                end);
                if r38 then
                    task.wait(0.5);
                    o[bS[22]](S, v1.WaitForChild(v1, "HumanoidRootPart"));
                end;
                return; 
            end);
            return; 
        end;
        bS[23] = 130;
        o[bS[23]] = bS[24];
        bS[24] = 131;
        bS[25] = function(...)
            v1 = Instance.new("ScreenGui");
            v1.Name = "FlightAnimationUI";
            v1.ResetOnSpawn = false;
            v3 = r29;
            v1.Parent = v3.WaitForChild(v3, "PlayerGui");
            r107 = Instance.new("ImageButton");
            r107.Name = "ToggleButton";
            r107.Size = UDim2.new(0, r73, 0, r74);
            r107.Position = UDim2.new(1, -70, .1, 0);
            r107.AnchorPoint = Vector2.new(1, 0);
            r107.BackgroundColor3 = Color3.fromRGB(90, 50, 140);
            r107.BackgroundTransparency = .1;
            r107.Image = "rbxassetid://135684785837881";
            r107.ScaleType = Enum.ScaleType.Fit;
            r107.ImageColor3 = Color3.fromRGB(240, 200, 255);
            r107.AutoButtonColor = false;
            r107.Parent = v1;
            S = Instance.new("UIGradient");
            S.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 70, 180)),
                ColorSequenceKeypoint.new(.3, Color3.fromRGB(160, 100, 220)),
                ColorSequenceKeypoint.new(.7, Color3.fromRGB(180, 120, 240)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 70, 180))
            });
            S.Rotation = 45;
            S.Parent = r107;
            v8 = r27;
            N = v8.Create(v8, S, TweenInfo.new(4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
                ["Rotation"] = 405
            });
            N.Play(N);
            q = Instance.new("ImageLabel");
            q.Name = "OuterGlow";
            q.Size = UDim2.new(1, 40, 1, 40);
            q.Position = UDim2.new(0, -20, 0, -20);
            q.BackgroundTransparency = 1;
            q.Image = "rbxassetid://5028857084";
            q.ImageColor3 = Color3.fromRGB(100, 50, 150);
            q.ImageTransparency = .8;
            q.ScaleType = Enum.ScaleType.Slice;
            q.SliceCenter = Rect.new(24, 24, 276, 276);
            q.ZIndex = -1;
            q.Parent = r107;
            r138 = Instance.new("ImageLabel");
            r138.Name = "InnerGlow";
            r138.Size = UDim2.new(1, 25, 1, 25);
            r138.Position = UDim2.new(0, -12.5, 0, -12.5);
            r138.BackgroundTransparency = 1;
            r138.Image = "rbxassetid://5028857084";
            r138.ImageColor3 = Color3.fromRGB(160, 100, 220);
            r138.ImageTransparency = .6;
            r138.ScaleType = Enum.ScaleType.Slice;
            r138.SliceCenter = Rect.new(24, 24, 276, 276);
            r138.ZIndex = -1;
            r138.Parent = r107;
            v8 = r27;
            P = v8.Create(v8, q, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
                ["ImageTransparency"] = .6
            });
            P.Play(P);
            v8 = r27;
            v2 = v8.Create(v8, r138, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
                ["ImageTransparency"] = .4
            });
            v2.Play(v2);
            v7 = Instance.new("UICorner");
            v7.CornerRadius = UDim.new(0.5, 0);
            v7.Parent = r107;
            o[PS] = false;
            o[bS[1]] = 0;
            o[bS[2]] = .2;
            v6 = r107.InputBegan;
            v6.Connect(v6, function(arg1_21, ...)
                N = Enum.UserInputType;
                if arg1_21.UserInputType == N.MouseButton1 then
                    o[PS] = true;
                    o[bS[1]] = os.clock();
                    v3 = r27;
                    N = v3.Create(v3, r107, TweenInfo.new(.1), {
                        ["Size"] = UDim2.new(0, r73 - 2, 0, r74 - 2),
                        ["BackgroundTransparency"] = .2
                    });
                    N.Play(N);
                    v3 = r27;
                    N = v3.Create(v3, r138, TweenInfo.new(.1), {
                        ["ImageTransparency"] = .3
                    });
                    N.Play(N);
                end;
                return; 
            end);
            v6 = r107.InputEnded;
            v6.Connect(v6, function(arg1_22, ...)
                N = Enum.UserInputType;
                if arg1_22.UserInputType == N.MouseButton1 then
                    if o[PS] and os.clock() - o[bS[1]] < o[bS[2]] then
                        r138();
                    end;
                    o[PS] = false;
                    v3 = r27;
                    N = v3.Create(v3, r107, TweenInfo.new(.1), {
                        ["Size"] = UDim2.new(0, r73, 0, r74),
                        ["BackgroundTransparency"] = .1
                    });
                    N.Play(N);
                    v3 = r27;
                    N = v3.Create(v3, r138, TweenInfo.new(.1), {
                        ["ImageTransparency"] = .6
                    });
                    N.Play(N);
                end;
                return; 
            end);
            v6 = r107.MouseLeave;
            v6.Connect(v6, function(...)
                if o[PS] then
                    o[PS] = false;
                    v3 = r27;
                    v1 = v3.Create(v3, r107, TweenInfo.new(.1), {
                        ["Size"] = UDim2.new(0, r73, 0, r74),
                        ["BackgroundTransparency"] = .1
                    });
                    v1.Play(v1);
                    v3 = r27;
                    v1 = v3.Create(v3, r138, TweenInfo.new(.1), {
                        ["ImageTransparency"] = .6
                    });
                    v1.Play(v1);
                end;
                return; 
            end);
            v6 = r27;
            r = v6.Create(v6, r107, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
                ["Size"] = UDim2.new(0, r73 + 2, 0, r74 + 2)
            });
            r.Play(r);
            o[xS] = Instance.new("Frame");
            o[xS].Name = "MainFrame";
            o[xS].Size = UDim2.new(.38, 0, .86, 0);
            o[xS].Position = UDim2.new(1, 400, 0.5, 0);
            o[xS].AnchorPoint = Vector2.new(1, 0.5);
            o[xS].BackgroundColor3 = Color3.fromRGB(10, 5, 20);
            o[xS].BackgroundTransparency = .1;
            o[xS].BorderSizePixel = 0;
            o[xS].ClipsDescendants = true;
            o[xS].Visible = false;
            o[xS].Parent = v1;
            v10 = Instance.new("UIGradient");
            v10.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 10, 35)),
                ColorSequenceKeypoint.new(.2, Color3.fromRGB(30, 15, 50)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(40, 20, 65)),
                ColorSequenceKeypoint.new(.8, Color3.fromRGB(30, 15, 50)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 10, 35))
            });
            v10.Rotation = 90;
            v10.Parent = o[xS];
            v6 = r27;
            t = v6.Create(v6, v10, TweenInfo.new(8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
                ["Rotation"] = 450
            });
            t.Play(t);
            F = Instance.new("UICorner");
            F.CornerRadius = UDim.new(0, 20);
            F.Parent = o[xS];
            J = Instance.new("Frame");
            J.Name = "Border";
            J.Size = UDim2.new(1, 6, 1, 6);
            J.Position = UDim2.new(0, -3, 0, -3);
            J.BackgroundTransparency = 1;
            J.ZIndex = -1;
            J.Parent = o[xS];
            G = Instance.new("UIGradient");
            G.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 80, 220)),
                ColorSequenceKeypoint.new(.3, Color3.fromRGB(220, 120, 255)),
                ColorSequenceKeypoint.new(.7, Color3.fromRGB(160, 60, 200)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 80, 220))
            });
            G.Rotation = 0;
            G.Parent = J;
            v6 = r27;
            v = v6.Create(v6, G, TweenInfo.new(4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
                ["Rotation"] = 360
            });
            v.Play(v);
            s = Instance.new("ImageLabel");
            s.Name = "RadiantGlow";
            s.Size = UDim2.new(1, 80, 1, 80);
            s.Position = UDim2.new(0, -40, 0, -40);
            s.BackgroundTransparency = 1;
            s.Image = "rbxassetid://5028857084";
            s.ImageColor3 = Color3.fromRGB(180, 120, 240);
            s.ImageTransparency = .9;
            s.ScaleType = Enum.ScaleType.Slice;
            s.SliceCenter = Rect.new(24, 24, 276, 276);
            s.ZIndex = -3;
            s.Parent = o[xS];
            k = Instance.new("ImageLabel");
            k.Name = "OuterGlow";
            k.Size = UDim2.new(1, 50, 1, 50);
            k.Position = UDim2.new(0, -25, 0, -25);
            k.BackgroundTransparency = 1;
            k.Image = "rbxassetid://5028857084";
            k.ImageColor3 = Color3.fromRGB(120, 70, 180);
            k.ImageTransparency = .7;
            k.ScaleType = Enum.ScaleType.Slice;
            k.SliceCenter = Rect.new(24, 24, 276, 276);
            k.ZIndex = -2;
            k.Parent = o[xS];
            g = Instance.new("ImageLabel");
            g.Name = "InnerGlow";
            g.Size = UDim2.new(1, 30, 1, 30);
            g.Position = UDim2.new(0, -15, 0, -15);
            g.BackgroundTransparency = 1;
            g.Image = "rbxassetid://5028857084";
            g.ImageColor3 = Color3.fromRGB(160, 100, 220);
            g.ImageTransparency = 0.5;
            g.ScaleType = Enum.ScaleType.Slice;
            g.SliceCenter = Rect.new(24, 24, 276, 276);
            g.ZIndex = -1;
            g.Parent = o[xS];
            v6 = r27;
            Q = v6.Create(v6, s, TweenInfo.new(5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
                ["ImageTransparency"] = .85
            });
            Q.Play(Q);
            v6 = r27;
            h = v6.Create(v6, k, TweenInfo.new(4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
                ["ImageTransparency"] = 0.5
            });
            h.Play(h);
            v6 = r27;
            z = v6.Create(v6, g, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
                ["ImageTransparency"] = .3
            });
            z.Play(z);
            L = Instance.new("Frame");
            L.Name = "TitleBar";
            L.Size = UDim2.new(1, 0, .12, 0);
            L.Position = UDim2.new(0, 0, 0, 0);
            L.BackgroundColor3 = Color3.fromRGB(25, 15, 40);
            L.BackgroundTransparency = .2;
            L.BorderSizePixel = 0;
            L.Parent = o[xS];
            CL = Instance.new("UIGradient");
            CL.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 20, 65)),
                ColorSequenceKeypoint.new(.4, Color3.fromRGB(60, 30, 95)),
                ColorSequenceKeypoint.new(.6, Color3.fromRGB(80, 40, 125)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 20, 65))
            });
            CL.Rotation = 90;
            CL.Parent = L;
            B = Instance.new("UICorner");
            B.CornerRadius = UDim.new(0, 20);
            B.Parent = L;
            e = Instance.new("ImageLabel");
            e.Size = UDim2.new(1, 25, 1, 25);
            e.Position = UDim2.new(0, -12.5, 0, -12.5);
            e.BackgroundTransparency = 1;
            e.Image = "rbxassetid://5028857084";
            e.ImageColor3 = Color3.fromRGB(140, 90, 190);
            e.ImageTransparency = .6;
            e.ScaleType = Enum.ScaleType.Slice;
            e.SliceCenter = Rect.new(24, 24, 276, 276);
            e.ZIndex = -1;
            e.Parent = L;
            y = Instance.new("TextLabel");
            y.Name = "Title";
            y.Size = UDim2.new(.7, 0, .8, 0);
            y.Position = UDim2.new(.05, 0, .1, 0);
            y.BackgroundTransparency = 1;
            y.Text = "INVINCIBLE FLY v1.147";
            y.TextColor3 = Color3.fromRGB(255, 255, 255);
            y.TextScaled = true;
            y.Font = Enum.Font.GothamBlack;
            y.TextXAlignment = Enum.TextXAlignment.Left;
            y.TextStrokeColor3 = Color3.fromRGB(120, 80, 180);
            y.TextStrokeTransparency = 0.5;
            y.Parent = L;
            mL = Instance.new("UIGradient");
            mL.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(220, 180, 255)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 220, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 150, 240))
            });
            mL.Rotation = 0;
            mL.Parent = y;
            v6 = r27;
            Y = v6.Create(v6, mL, TweenInfo.new(5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
                ["Rotation"] = 360
            });
            Y.Play(Y);
            pL = Instance.new("Frame");
            pL.Name = "TabSwitcher";
            pL.Size = UDim2.new(.9, 0, .06, 0);
            pL.Position = UDim2.new(.05, 0, .13, 0);
            pL.BackgroundColor3 = Color3.fromRGB(30, 18, 45);
            pL.BackgroundTransparency = .2;
            pL.Parent = o[xS];
            xL = Instance.new("UICorner");
            xL.CornerRadius = UDim.new(0, 12);
            xL.Parent = pL;
            EL = Instance.new("ImageLabel");
            EL.Size = UDim2.new(1, 8, 1, 8);
            EL.Position = UDim2.new(0, -4, 0, -4);
            EL.BackgroundTransparency = 1;
            EL.Image = "rbxassetid://5028857084";
            EL.ImageColor3 = Color3.fromRGB(100, 60, 160);
            EL.ImageTransparency = .7;
            EL.ScaleType = Enum.ScaleType.Slice;
            EL.SliceCenter = Rect.new(24, 24, 276, 276);
            EL.ZIndex = -1;
            EL.Parent = pL;
            r139 = Instance.new("TextButton");
            r139.Name = "AnimationsTab";
            r139.Size = UDim2.new(.48, 0, 0.75, 0);
            r139.Position = UDim2.new(.01, 0, 0.125, 0);
            r139.BackgroundColor3 = Color3.fromRGB(40, 20, 65);
            r139.BackgroundTransparency = .1;
            r139.Text = "ANIMATIONS";
            r139.TextColor3 = Color3.fromRGB(255, 255, 255);
            r139.TextSize = 12;
            r139.Font = Enum.Font.GothamBold;
            r139.AutoButtonColor = false;
            r139.Parent = pL;
            HL = Instance.new("UICorner");
            HL.CornerRadius = UDim.new(0, 8);
            HL.Parent = r139;
            r140 = Instance.new("UIGradient");
            r140.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 25, 75)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 30, 85))
            });
            r140.Rotation = 90;
            r140.Parent = r139;
            r141 = Instance.new("TextButton");
            r141.Name = "SettingsTab";
            r141.Size = UDim2.new(.48, 0, 0.75, 0);
            r141.Position = UDim2.new(.51, 0, 0.125, 0);
            r141.BackgroundColor3 = Color3.fromRGB(40, 20, 65);
            r141.BackgroundTransparency = .2;
            r141.Text = "SETTINGS";
            r141.TextColor3 = Color3.fromRGB(200, 200, 200);
            r141.TextSize = 12;
            r141.Font = Enum.Font.GothamBold;
            r141.AutoButtonColor = false;
            r141.Parent = pL;
            oL = Instance.new("UICorner");
            oL.CornerRadius = UDim.new(0, 8);
            oL.Parent = r141;
            r142 = Instance.new("UIGradient");
            r142.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 25, 75)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 30, 85))
            });
            r142.Rotation = 90;
            r142.Parent = r141;
            r143 = Instance.new("Frame");
            r143.Name = "TabSelector";
            r143.Size = UDim2.new(.48, 0, .1, 0);
            r143.Position = UDim2.new(.01, 0, .9, 0);
            r143.BackgroundColor3 = Color3.fromRGB(180, 130, 230);
            r143.BorderSizePixel = 0;
            r143.Parent = pL;
            SL = Instance.new("UICorner");
            SL.CornerRadius = UDim.new(0, 4);
            SL.Parent = r143;
            NL = Instance.new("ImageLabel");
            NL.Size = UDim2.new(1, 6, 1, 6);
            NL.Position = UDim2.new(0, -3, 0, -3);
            NL.BackgroundTransparency = 1;
            NL.Image = "rbxassetid://5028857084";
            NL.ImageColor3 = Color3.fromRGB(200, 150, 250);
            NL.ImageTransparency = .6;
            NL.ScaleType = Enum.ScaleType.Slice;
            NL.SliceCenter = Rect.new(24, 24, 276, 276);
            NL.ZIndex = -1;
            NL.Parent = r143;
            r144 = Instance.new("ScrollingFrame");
            r144.Name = "SettingsFrame";
            r144.Size = UDim2.new(1, -30, 0.5, 0);
            r144.Position = UDim2.new(0, 15, .22, 0);
            r144.BackgroundTransparency = 1;
            r144.ScrollBarThickness = 8;
            r144.ScrollBarImageColor3 = Color3.fromRGB(150, 100, 200);
            r144.ScrollBarImageTransparency = .3;
            r144.Visible = false;
            r144.Parent = o[xS];
            local function r145(arg1_23, ...)
                v1 = arg1_23;
                S = v1;
                r45 = v1;
                if v1 then
                    N = UDim2.new(.51, 0, .9, 0);
                end;
                v3 = v1;
                v8 = v1;
                if v1 then
                    v3 = r27;
                    N = v3.Create(v3, r143, TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        ["Position"] = N
                    });
                    N.Play(N);
                    r139.BackgroundTransparency = v1 and .2 or .1;
                    r141.BackgroundTransparency = v1 and .1 or .2;
                    v3 = r139;
                    P = v1;
                    N = "TextColor3";
                    q = v1 and Color3.fromRGB(200, 200, 200);
                    v8 = v1;
                    if v1 then
                        r139[r15[r16("\x1a\x80\xce\xadn\xa7Oe\x83\xd1", v7)]] = v4 and Color3.fromRGB(200, 200, 200);
                        v3 = r141;
                        N = "TextColor3";
                        P = v1;
                        if v1 then
                            v4 = Color3.fromRGB(255, 255, 255);
                        end;
                        v8 = v1;
                        q = v1;
                        if v1 then
                            r141[N] = v4;
                            v8 = P;
                            if v1 then
                                v3 = r27;
                                N = v3.Create(v3, r140, TweenInfo.new(.3), {
                                    ["Rotation"] = 270
                                });
                                N.Play(N);
                                v3 = r27;
                                N = v3.Create(v3, r142, TweenInfo.new(.3), {
                                    ["Rotation"] = 90
                                });
                                N.Play(N);
                            else
                                v3 = r27;
                                N = v3.Create(v3, r140, TweenInfo.new(.3), {
                                    ["Rotation"] = 90
                                });
                                N.Play(N);
                                v3 = r27;
                                N = v3.Create(v3, r142, TweenInfo.new(.3), {
                                    ["Rotation"] = 270
                                });
                                N.Play(N);
                            end;
                            r105.Visible = not v1;
                            P = v8;
                            r144.Visible = v1;
                            N = v8;
                            if v1 then
                                q = UDim2.new(0, 15, .73, 0);
                            end;
                            v8 = P;
                            v3 = v1;
                            if v1 then
                                q = v8;
                                N = q;
                                P = arg1_23;
                                v3 = P and UDim2.new(0, 15, .86, 0);
                                v8 = v8;
                                if P then
                                    v8 = v8;
                                    statsFrame.Position = q;
                                    hoverFrame.Position = P and UDim2.new(0, 15, .86, 0);
                                    return;
                                else
                                    v3 = UDim2.new(0, 15, .86, 0);
                                end;
                            else
                                v3 = UDim2.new(0, 15, .73, 0);
                            end;
                        else
                            q = Color3.fromRGB(200, 200, 200);
                        end;
                    else
                        q = Color3.fromRGB(255, 255, 255);
                    end;
                else
                    v3 = UDim2.new(.01, 0, .9, 0);
                end; 
            end;
            lL = r139.MouseEnter;
            lL.Connect(lL, function(...)
                if r45 then
                    v8 = r27;
                    v3 = v8.Create(v8, r139, TweenInfo.new(.2), {
                        ["BackgroundTransparency"] = .15,
                        ["Size"] = UDim2.new(.49, 0, .8, 0)
                    });
                    v3.Play(v3);
                end;
                return; 
            end);
            lL = r139.MouseLeave;
            lL.Connect(lL, function(...)
                v8 = r27;
                v7 = v8;
                v4 = v8;
                v3 = v8.Create(v8, r139, TweenInfo.new(.2), {
                    ["BackgroundTransparency"] = r45 and .2 or .1,
                    ["Size"] = UDim2.new(.48, 0, 0.75, 0)
                });
                v3.Play(v3);
                return; 
            end);
            lL = r139.MouseButton1Click;
            lL.Connect(lL, function(...)
                if not r45 then
                    return;
                end;
                r145(false);
                return; 
            end);
            lL = r141.MouseEnter;
            lL.Connect(lL, function(...)
                v3 = r45;
                if not v3 then
                    v8 = r27;
                    v3 = v8.Create(v8, r141, TweenInfo.new(.2), {
                        ["BackgroundTransparency"] = .15,
                        ["Size"] = UDim2.new(.49, 0, .8, 0)
                    });
                    v3.Play(v3);
                end;
                return; 
            end);
            lL = r141.MouseLeave;
            lL.Connect(lL, function(...)
                v8 = r27;
                v7 = r27;
                v4 = v8;
                v3 = v8.Create(v8, r141, TweenInfo.new(.2), {
                    ["BackgroundTransparency"] = r45 and .1 or .2,
                    ["Size"] = UDim2.new(.48, 0, 0.75, 0)
                });
                v3.Play(v3);
                return; 
            end);
            lL = r141.MouseButton1Click;
            lL.Connect(lL, function(...)
                if r45 then
                    return;
                end;
                r145(true);
                return; 
            end);
            r146 = Instance.new("ImageButton");
            kL = 26768919130289;
            r146.Name = "CloseButton";
            r146.Size = UDim2.new(.08, 0, .6, 0);
            r146.Position = UDim2.new(.9, 0, .2, 0);
            r146.BackgroundColor3 = Color3.fromRGB(130, 80, 180);
            r146.BackgroundTransparency = .1;
            r146.Image = "rbxassetid://3926305904";
            r146.ImageColor3 = Color3.fromRGB(255, 240, 255);
            r146.ImageRectOffset = Vector2.new(284, 4);
            r146.ImageRectSize = Vector2.new(24, 24);
            r146.AutoButtonColor = false;
            r146.Parent = L;
            bL = Instance.new("UIGradient");
            bL.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 100, 200)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(130, 80, 180))
            });
            bL.Rotation = 90;
            bL.Parent = r146;
            dL = Instance.new("UICorner");
            dL.CornerRadius = UDim.new(0.5, 0);
            dL.Parent = r146;
            r147 = Instance.new("ImageLabel");
            r147.Size = UDim2.new(1, 15, 1, 15);
            r147.Position = UDim2.new(0, -7.5, 0, -7.5);
            r147.BackgroundTransparency = 1;
            r147.Image = "rbxassetid://5028857084";
            r147.ImageColor3 = Color3.fromRGB(160, 110, 210);
            r147.ImageTransparency = .7;
            r147.ScaleType = Enum.ScaleType.Slice;
            r147.SliceCenter = Rect.new(24, 24, 276, 276);
            r147.ZIndex = -1;
            r147.Parent = r146;
            UL = r146.MouseEnter;
            UL.Connect(UL, function(...)
                v8 = r27;
                v3 = v8.Create(v8, r146, TweenInfo.new(.2), {
                    ["BackgroundColor3"] = Color3.fromRGB(180, 120, 220),
                    ["Size"] = UDim2.new(.09, 0, .65, 0)
                });
                v3.Play(v3);
                v8 = r27;
                v3 = v8.Create(v8, r147, TweenInfo.new(.2), {
                    ["ImageTransparency"] = 0.5
                });
                v3.Play(v3);
                return; 
            end);
            UL = r146.MouseLeave;
            UL.Connect(UL, function(...)
                v8 = r27;
                v3 = v8.Create(v8, r146, TweenInfo.new(.2), {
                    ["BackgroundColor3"] = Color3.fromRGB(130, 80, 180),
                    ["Size"] = UDim2.new(.08, 0, .6, 0)
                });
                v3.Play(v3);
                v8 = r27;
                v3 = v8.Create(v8, r147, TweenInfo.new(.2), {
                    ["ImageTransparency"] = .7
                });
                v3.Play(v3);
                return; 
            end);
            r105 = Instance.new("ScrollingFrame");
            r105.Name = "AnimationScroller";
            r105.Size = UDim2.new(1, -30, 0.5, 0);
            r105.Position = UDim2.new(0, 15, .22, 0);
            r105.BackgroundTransparency = 1;
            r105.ScrollBarThickness = 8;
            r105.ScrollBarImageColor3 = Color3.fromRGB(150, 100, 200);
            r105.ScrollBarImageTransparency = .3;
            r105.Parent = o[xS];
            r148 = Instance.new("UIListLayout");
            r148.Name = "ListLayout";
            r148.Padding = UDim.new(0, 12);
            r148.SortOrder = Enum.SortOrder.LayoutOrder;
            r148.Parent = r105;
            OL = Instance.new("Frame");
            OL.Name = "StatsFrame";
            OL.Size = UDim2.new(1, -30, 0, 80);
            OL.Position = UDim2.new(0, 15, .73, 0);
            OL.BackgroundColor3 = Color3.fromRGB(30, 18, 45);
            OL.BackgroundTransparency = .2;
            OL.Parent = o[xS];
            DL = Instance.new("UIGradient");
            DL.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 22, 60)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(50, 28, 75)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 22, 60))
            });
            DL.Rotation = 90;
            DL.Parent = OL;
            VL = Instance.new("UICorner");
            VL.CornerRadius = UDim.new(0, 15);
            VL.Parent = OL;
            ML = Instance.new("ImageLabel");
            ML.Size = UDim2.new(1, 15, 1, 15);
            ML.Position = UDim2.new(0, -7.5, 0, -7.5);
            ML.BackgroundTransparency = 1;
            ML.Image = "rbxassetid://5028857084";
            ML.ImageColor3 = Color3.fromRGB(100, 60, 160);
            ML.ImageTransparency = .7;
            ML.ScaleType = Enum.ScaleType.Slice;
            ML.SliceCenter = Rect.new(24, 24, 276, 276);
            ML.ZIndex = -1;
            ML.Parent = OL;
            WL = Instance.new("TextLabel");
            WL.Name = "StatsTitle";
            WL.Size = UDim2.new(1, -10, .2, 0);
            WL.Position = UDim2.new(0, 10, 0, 5);
            WL.BackgroundTransparency = 1;
            WL.Text = "FLIGHT STATS";
            WL.TextColor3 = Color3.fromRGB(230, 200, 255);
            WL.TextSize = 14;
            WL.TextXAlignment = Enum.TextXAlignment.Left;
            WL.Font = Enum.Font.GothamBold;
            WL.Parent = OL;
            jL = Instance.new("UIGradient");
            vL = r16("\xe7\xa6\xe9\x1e\xc5\"\xbe", kL);
            jL.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 150, 240)),
                ColorSequenceKeypoint.new(1, Color3[r15[vL]](180, 130, 220))
            });
            jL.Parent = WL;
            r149 = Instance.new("TextLabel");
            r149.Name = "SpeedStat";
            r149.Size = UDim2.new(.45, 0, .3, 0);
            r149.Position = UDim2.new(0, 10, 0.25, 0);
            r149.BackgroundTransparency = 1;
            r149.Text = "SPEED: " .. r62;
            r149.TextColor3 = Color3.fromRGB(210, 180, 240);
            r149.TextSize = 12;
            r149.TextXAlignment = Enum.TextXAlignment.Left;
            r149.Font = Enum.Font.GothamMedium;
            r149.Parent = OL;
            r150 = Instance.new("TextLabel");
            r150.Name = "BoostStat";
            r150.Size = UDim2.new(.45, 0, .3, 0);
            r150.Position = UDim2.new(0.5, 0, 0.25, 0);
            r150.BackgroundTransparency = 1;
            v8 = false;
            r150.Text = "BOOST: " .. (r40 == 0 and "OFF" or "LEVEL " .. r40);
            r150.TextColor3 = Color3.fromRGB(210, 180, 240);
            r150.TextSize = 12;
            r150.TextXAlignment = Enum.TextXAlignment.Left;
            r150.Font = Enum.Font.GothamMedium;
            r150.Parent = OL;
            r151 = Instance.new("TextLabel");
            r151.Name = "StatusStat";
            FL = 27544746340890;
            r151.Size = UDim2.new(1, -10, .3, 0);
            r151.Position = UDim2[r15[r16("\xdd\xa7\x1c", FL)]](0, 10, .6, 0);
            r151.BackgroundTransparency = 1;
            GL = false;
            JL = r38;
            v8 = GL;
            r151.Text = "STATUS: " .. (JL and "FLYING" or "GROUNDED");
            KL = r151;
            TL = false;
            rL = "TextColor3";
            tL = r38;
            cL = false;
            IL = tL;
            if tL then
                IL = Color3.fromRGB(120, 255, 120);
            end;
            v8 = TL;
            RL = IL;
            if IL then
                o[aL].TextColor3 = IL;
                r151.TextSize = 12;
                r151.TextXAlignment = Enum.TextXAlignment.Left;
                r151.Font = Enum.Font.GothamMedium;
                RL = Instance.new("Frame");
                r151.Parent = RL;
                bS[19] = 2008601494439;
                rL = Instance.new("Frame");
                rL.Name = "HoverSettings";
                rL.Size = UDim2.new(1, -30, 0, 170);
                rL.Position = UDim2.new(0, 15, .86, 0);
                bS[7] = 5598574873135;
                bS[5] = 20933467776531;
                rL.BackgroundColor3 = Color3.fromRGB(30, 18, 45);
                rL.BackgroundTransparency = .2;
                rL.Parent = o[xS];
                RL = Instance.new("UIGradient");
                bS[24] = 8859030147101;
                RL.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 22, 60)),
                    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(50, 28, 75)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 22, 60))
                });
                RL.Rotation = 90;
                RL.Parent = rL;
                cL = Instance.new("UICorner");
                cL.CornerRadius = UDim.new(0, 15);
                cL.Parent = rL;
                IL = Instance.new("ImageLabel");
                IL.Size = UDim2.new(1, 15, 1, 15);
                IL.Position = UDim2.new(0, -7.5, 0, -7.5);
                IL.BackgroundTransparency = 1;
                IL.Image = "rbxassetid://5028857084";
                IL.ImageColor3 = Color3.fromRGB(100, 60, 160);
                IL.ImageTransparency = .7;
                bS[1] = 28646421885979;
                IL.ScaleType = Enum.ScaleType.Slice;
                IL.SliceCenter = Rect.new(24, 24, 276, 276);
                IL.ZIndex = -1;
                IL.Parent = rL;
                KL = r27;
                TL = KL.Create(KL, rL, TweenInfo.new(5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
                    ["BackgroundTransparency"] = 0.25
                });
                TL.Play(TL);
                tL = Instance.new("TextLabel");
                tL.Name = "Title";
                bS[11] = 29944158041719;
                tL.Size = UDim2.new(1, -10, .2, 0);
                tL.Position = UDim2.new(0, 10, 0, 5);
                tL.BackgroundTransparency = 1;
                tL.Text = "HOVER SETTINGS";
                tL.TextColor3 = Color3.fromRGB(230, 200, 255);
                tL.TextSize = 14;
                tL.TextXAlignment = Enum.TextXAlignment.Left;
                tL.Font = Enum.Font.GothamBold;
                tL.Parent = rL;
                bS[8] = 25811561574131;
                GL = Instance.new("UIGradient");
                GL.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 150, 240)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 130, 220))
                });
                GL.Parent = tL;
                JL = Instance.new("Frame");
                JL.Name = "HeightContainer";
                JL.Size = UDim2.new(1, -20, 0.25, 0);
                JL.Position = UDim2.new(0, 10, .15, 0);
                JL.BackgroundTransparency = 1;
                bS[27] = 24673475734753;
                JL.Parent = rL;
                FL = Instance.new("TextLabel");
                FL.Name = "Label";
                FL.Size = UDim2.new(0.5, 0, 1, 0);
                FL.Position = UDim2.new(0, 0, 0, 0);
                FL.BackgroundTransparency = 1;
                FL.Text = "HOVER HEIGHT";
                FL.TextColor3 = Color3.fromRGB(210, 180, 240);
                FL.TextXAlignment = Enum.TextXAlignment.Left;
                FL.TextSize = 12;
                FL.Font = Enum.Font.GothamMedium;
                FL.Parent = JL;
                vL = Instance.new("UIGradient");
                vL.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(220, 190, 250)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 170, 230))
                });
                vL.Parent = FL;
                r152 = Instance.new("TextLabel");
                r152.Name = "Value";
                r152.Size = UDim2.new(.2, 0, 1, 0);
                bS[15] = 33705895624015;
                r152.Position = UDim2.new(.8, 0, 0, 0);
                r152.BackgroundTransparency = 1;
                r152.Text = string.format("%.1f", r51);
                r152.TextColor3 = Color3.fromRGB(250, 230, 255);
                r152.TextSize = 12;
                r152.Font = Enum.Font.GothamBold;
                r152.Parent = JL;
                kL = Instance.new("Frame");
                bS[20] = 32267075353265;
                bS[6] = 22507003193584;
                kL.Name = "Slider";
                kL.Size = UDim2.new(1, 0, 0, 10);
                kL.Position = UDim2.new(0, 0, 1, -15);
                kL.BackgroundColor3 = Color3.fromRGB(50, 30, 70);
                kL.Parent = JL;
                gL = Instance.new("UICorner");
                gL.CornerRadius = UDim.new(0.5, 0);
                gL.Parent = kL;
                r153 = Instance.new("Frame");
                r153.Name = "Fill";
                r153.Size = UDim2.new((r51 - 0.5) / 1.5, 1, 1, 0);
                bS[12] = 27964179329757;
                r153.Position = UDim2.new(0, 0, 0, 0);
                r153.BackgroundColor3 = Color3.fromRGB(180, 130, 230);
                r153.Parent = kL;
                hL = Instance.new("UICorner");
                hL.CornerRadius = UDim.new(0.5, 0);
                hL.Parent = r153;
                zL = Instance.new("ImageLabel");
                zL.Size = UDim2.new(1, 12, 1, 12);
                zL.Position = UDim2.new(0, -6, 0, -6);
                zL.BackgroundTransparency = 1;
                zL.Image = "rbxassetid://5028857084";
                zL.ImageColor3 = Color3.fromRGB(180, 130, 230);
                zL.ImageTransparency = .7;
                zL.ScaleType = Enum.ScaleType.Slice;
                zL.SliceCenter = Rect.new(24, 24, 276, 276);
                zL.ZIndex = -1;
                zL.Parent = r153;
                LL = Instance.new("Frame");
                bS[21] = 22516932225269;
                LL.Name = "SpeedContainer";
                LL.Size = UDim2.new(1, -20, 0.25, 0);
                LL.Position = UDim2.new(0, 10, .42, 0);
                LL.BackgroundTransparency = 1;
                LL.Parent = rL;
                eL = Instance.new("TextLabel");
                eL.Name = "Label";
                eL.Size = UDim2.new(0.5, 0, 1, 0);
                eL.Position = UDim2.new(0, 0, 0, 0);
                eL.BackgroundTransparency = 1;
                eL.Text = "HOVER SPEED";
                eL.TextColor3 = Color3.fromRGB(210, 180, 240);
                eL.TextXAlignment = Enum.TextXAlignment.Left;
                eL.TextSize = 12;
                eL.Font = Enum.Font.GothamMedium;
                eL.Parent = LL;
                BL = Instance.new("UIGradient");
                bS[4] = 24530015775902;
                BL.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(220, 190, 250)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 170, 230))
                });
                BL.Parent = eL;
                r154 = Instance.new("TextLabel");
                r154.Name = "Value";
                r154.Size = UDim2.new(.2, 0, 1, 0);
                r154.Position = UDim2.new(.8, 0, 0, 0);
                r154.BackgroundTransparency = 1;
                r154.Text = string.format("%.1f", r52);
                r154.TextColor3 = Color3.fromRGB(250, 230, 255);
                r154.TextSize = 12;
                bS[26] = 33026682600467;
                r154.Font = Enum.Font.GothamBold;
                r154.Parent = LL;
                YL = Instance.new("Frame");
                YL.Name = "Slider";
                YL.Size = UDim2.new(1, 0, 0, 10);
                YL.Position = UDim2.new(0, 0, 1, -15);
                YL.BackgroundColor3 = Color3.fromRGB(50, 30, 70);
                YL.Parent = LL;
                bS[10] = 85239644199;
                pS = Instance.new("UICorner");
                pS.CornerRadius = UDim.new(0.5, 0);
                pS.Parent = YL;
                r155 = Instance.new("Frame");
                r155.Name = "Fill";
                r155.Size = UDim2.new((r52 - 1) / 4, 1, 1, 0);
                bS[25] = 9460273582389;
                r155.Position = UDim2.new(0, 0, 0, 0);
                r155.BackgroundColor3 = Color3.fromRGB(180, 130, 230);
                r155.Parent = YL;
                CS = Instance.new("UICorner");
                CS.CornerRadius = UDim.new(0.5, 0);
                CS.Parent = r155;
                xS = Instance.new("ImageLabel");
                xS.Size = UDim2.new(1, 12, 1, 12);
                xS.Position = UDim2.new(0, -6, 0, -6);
                xS.BackgroundTransparency = 1;
                xS.Image = "rbxassetid://5028857084";
                xS.ImageColor3 = Color3.fromRGB(180, 130, 230);
                xS.ImageTransparency = .7;
                bS[14] = 21399385614060;
                xS.ScaleType = Enum.ScaleType.Slice;
                xS.SliceCenter = Rect.new(24, 24, 276, 276);
                xS.ZIndex = -1;
                xS.Parent = r155;
                r156 = Instance.new("TextButton");
                bS[22] = 33491421936875;
                r156.Name = "ResetButton";
                r156.Size = UDim2.new(.8, 0, .2, 0);
                r156.Position = UDim2.new(.1, 0, 0.75, 0);
                r156.BackgroundColor3 = Color3.fromRGB(130, 80, 180);
                r156.BackgroundTransparency = .1;
                r156.Text = "RESET TO DEFAULTS";
                r156.TextColor3 = Color3.fromRGB(255, 240, 255);
                r156.TextSize = 12;
                r156.Font = Enum.Font.GothamBold;
                bS[13] = 14378008058407;
                r156.TextStrokeColor3 = Color3.fromRGB(80, 40, 120);
                r156.TextStrokeTransparency = .7;
                r156.Parent = rL;
                r157 = Instance.new("UIGradient");
                bS[3] = "\xdc\x88\xc2e}\x9c\x95";
                bS[1] = r16;
                bS[2] = bS[1](bS[3], bS[4]);
                bS[4] = "\xcc\x1a\xf9p\x97-\x97";
                bS[1] = 200;
                bS[1] = "\xc7\xee\xff";
                bS[2] = 27789204992652;
                bS[1] = r15;
                bS[2] = r16;
                bS[3] = bS[2](bS[4], bS[5]);
                bS[1] = 120;
                bS[2] = 220;
                bS[3] = 19806103643142;
                bS[2] = "x\xb9\x8f";
                bS[1] = r16(bS[2], bS[3]);
                bS[1] = "Color3";
                bS[5] = "\x01T\x04\x19O\x06\xf3";
                bS[2] = r15;
                bS[3] = r16;
                bS[4] = bS[3](bS[5], bS[6]);
                bS[1] = bS[2][bS[4]];
                bS[2] = 100;
                bS[3] = 200;
                bS[1] = 150;
                r157.Color = ColorSequence.new({
                    ColorSequenceKeypoint[r15[r16("y\xac\x8f", bS[1])]](0, Color3[r15[bS[2]]](150, 100, bS[1])),
                    ColorSequenceKeypoint[r15[r16(bS[1], bS[2])]](0.5, Color3[bS[1][bS[3]]](170, bS[1], bS[2])),
                    ColorSequenceKeypoint[r15[bS[1]]](1, Env[bS[1]][bS[1]](bS[1], bS[2], bS[3]))
                });
                r157.Rotation = 90;
                r157.Parent = r156;
                bS[4] = 457553789141;
                bS[16] = 34537966190290;
                wS = Instance.new("UICorner");
                wS.CornerRadius = UDim.new(0, 8);
                wS.Parent = r156;
                bS[3] = 12093414938111;
                r158 = Instance.new("ImageLabel");
                bS[17] = 33186427698269;
                r158.Size = UDim2.new(1, 15, 1, 15);
                bS[2] = 24808599760160;
                r158.Position = UDim2.new(0, -7.5, 0, -7.5);
                r158.BackgroundTransparency = 1;
                bS[6] = 14764480617179;
                r158.Image = "rbxassetid://5028857084";
                bS[1] = 26626346479726;
                r158.ImageColor3 = Color3.fromRGB(170, 120, 220);
                r158.ImageTransparency = .7;
                r158.ScaleType = Enum[r15[r16("E8\xf8\xe3\x18\xf1\xac\xbf\x08", bS[1])]].Slice;
                r158.SliceCenter = Rect.new(24, 24, 276, 276);
                bS[1] = 9015579414630;
                r158.ZIndex = -1;
                r158.Parent = r156;
                XS = r156.MouseEnter;
                XS.Connect(XS, function(...)
                    v8 = r27;
                    v3 = v8.Create(v8, r156, TweenInfo.new(.2), {
                        ["BackgroundTransparency"] = .05,
                        ["Size"] = UDim2.new(.82, 0, .22, 0)
                    });
                    v3.Play(v3);
                    v8 = r27;
                    v3 = v8.Create(v8, r157, TweenInfo.new(.2), {
                        ["Rotation"] = 270
                    });
                    v3.Play(v3);
                    v8 = r27;
                    v3 = v8.Create(v8, r158, TweenInfo.new(.2), {
                        ["ImageTransparency"] = 0.5
                    });
                    v3.Play(v3);
                    return; 
                end);
                XS = r156.MouseLeave;
                XS.Connect(XS, function(...)
                    v8 = r27;
                    v3 = v8.Create(v8, r156, TweenInfo.new(.2), {
                        ["BackgroundTransparency"] = .1,
                        ["Size"] = UDim2.new(.8, 0, .2, 0)
                    });
                    v3.Play(v3);
                    v8 = r27;
                    v3 = v8.Create(v8, r157, TweenInfo.new(.2), {
                        ["Rotation"] = 90
                    });
                    v3.Play(v3);
                    v8 = r27;
                    v3 = v8.Create(v8, r158, TweenInfo.new(.2), {
                        ["ImageTransparency"] = .7
                    });
                    v3.Play(v3);
                    return; 
                end);
                bS[18] = 2328587912252;
                SS = r15[r16("\xf6\xba\x0fu\xd2Yy\x0f\x8b#", bS[1])];
                bS[1] = "\xae\x1e\x98\xa7\xc1h\xb8\t\x98\x136\xf9\xee";
                bS[2] = "!z1\xb5\xd9AM\xdd\xc8";
                bS[1] = r16(bS[2], bS[3]);
                bS[3] = "\x81\x1b\xdb\xb5^\xec\x94\xfb";
                bS[1] = r16;
                bS[2] = bS[1](bS[3], bS[4]);
                bS[1] = r15;
                bS[5] = 14283797993979;
                bS[4] = "\xa6\r>\xd0[l\x99\x98\xc0H'\xc1\xf4`";
                bS[2] = r16;
                bS[3] = bS[2](bS[4], bS[5]);
                PS = bS[1][bS[3]];
                bS[2] = r15;
                bS[3] = r16;
                bS[5] = "H\x068\xf3\xf6\x99\x8e\xea\xaa";
                bS[4] = bS[3](bS[5], bS[6]);
                bS[1] = bS[2][bS[4]];
                bS[9] = 10897596093394;
                bS[3] = r15;
                bS[4] = r16;
                bS[6] = "\x83j\x97\xe8\xbe\x1f\xce\x81\x8d";
                bS[5] = bS[4](bS[6], bS[7]);
                bS[2] = bS[3][bS[5]];
                bS[4] = r15;
                bS[7] = "\xbbo\x16\xc5\x05>{\t\x97\x11";
                bS[5] = r16;
                bS[6] = bS[5](bS[7], bS[8]);
                bS[3] = bS[4][bS[6]];
                bS[8] = "4\xf87\xfd\xea\x88\xf8\xec\x95\xf0";
                bS[5] = r15;
                bS[6] = r16;
                bS[7] = bS[6](bS[8], bS[9]);
                bS[9] = "\xaa\x96\xb4\xae\xdb\xfd\x1f\x82,&\x9fG\xa3";
                bS[4] = bS[5][bS[7]];
                bS[6] = r15;
                bS[7] = r16;
                bS[8] = bS[7](bS[9], bS[10]);
                bS[10] = "\xd2\xb2\x15\ry\xd8\xd5\x94";
                bS[5] = bS[6][bS[8]];
                bS[7] = r15;
                bS[8] = r16;
                bS[9] = bS[8](bS[10], bS[11]);
                bS[6] = bS[7][bS[9]];
                bS[8] = r15;
                bS[11] = "\xc8\xcb\xd3\xc3.\xc8\xfaGY\x8f\xc9\xf1";
                bS[9] = r16;
                bS[10] = bS[9](bS[11], bS[12]);
                bS[7] = bS[8][bS[10]];
                bS[9] = r15;
                bS[12] = "\x8d79`\xc8z\\\xfeV\xb8";
                bS[10] = r16;
                bS[11] = bS[10](bS[12], bS[13]);
                bS[8] = bS[9][bS[11]];
                bS[10] = r15;
                bS[11] = r16;
                bS[13] = ".\"|t.?\xc4{j0\xf1u";
                bS[12] = bS[11](bS[13], bS[14]);
                bS[14] = "\xe3\xe7=\xca\xef\xd8'\xdf\x87\xcf\xf8\xa46=\xe1";
                bS[9] = bS[10][bS[12]];
                bS[11] = r15;
                bS[12] = r16;
                bS[13] = bS[12](bS[14], bS[15]);
                bS[10] = bS[11][bS[13]];
                bS[15] = "\xc9\x1bX\xf9\xce\x97I\xabz\xcfg6";
                bS[12] = r15;
                bS[13] = r16;
                bS[14] = bS[13](bS[15], bS[16]);
                bS[11] = bS[12][bS[14]];
                bS[13] = r15;
                bS[16] = "\x8b\nYO\xaa\xf3\t\xeb\xe0\x9d";
                bS[14] = r16;
                bS[15] = bS[14](bS[16], bS[17]);
                bS[12] = bS[13][bS[15]];
                bS[14] = r15;
                bS[17] = "\xdc\x8b\x98\xb5c\x0e\x0c\x12\xc5\xe7\xa0";
                bS[15] = r16;
                bS[16] = bS[15](bS[17], bS[18]);
                bS[13] = bS[14][bS[16]];
                bS[18] = "\xad=6\xa9|\xac\x8b\x8e\x86\xb6@";
                bS[15] = r15;
                bS[16] = r16;
                bS[17] = bS[16](bS[18], bS[19]);
                bS[14] = bS[15][bS[17]];
                bS[19] = "d\x93\xc5g\x01R:\xa6Vy]y";
                bS[16] = r15;
                bS[17] = r16;
                bS[18] = bS[17](bS[19], bS[20]);
                bS[15] = bS[16][bS[18]];
                bS[17] = r15;
                bS[18] = r16;
                bS[20] = "\xbf!}b\xb6m6\xfb\x0bLS";
                bS[19] = bS[18](bS[20], bS[21]);
                bS[16] = bS[17][bS[19]];
                bS[18] = r15;
                bS[21] = "\xab1#\xf5<\xa8\x16\xef![\x00\x0f\xa7Z";
                bS[23] = 18840953807429;
                bS[19] = r16;
                bS[20] = bS[19](bS[21], bS[22]);
                bS[22] = "\xec\x8dE\x84\\\x07\xcbyl";
                bS[17] = bS[18][bS[20]];
                bS[19] = r15;
                bS[20] = r16;
                bS[21] = bS[20](bS[22], bS[23]);
                bS[18] = bS[19][bS[21]];
                bS[23] = "o@\xdbM[g\x86\xff";
                bS[20] = r15;
                bS[21] = r16;
                bS[22] = bS[21](bS[23], bS[24]);
                bS[19] = bS[20][bS[22]];
                bS[21] = r15;
                bS[22] = r16;
                bS[24] = "uj;\xe0\xc2\xd3%\x9c\xb0\xdf";
                bS[23] = bS[22](bS[24], bS[25]);
                bS[20] = bS[21][bS[23]];
                bS[25] = "}\x0e\x91\x11\xc4*\x1ae\xb3\x10\xe6a\x1dR";
                bS[22] = r15;
                bS[23] = r16;
                bS[24] = bS[23](bS[25], bS[26]);
                bS[21] = bS[22][bS[24]];
                bS[26] = "G\xb5\xe8\xbb?\xe5Y\x93\x1b";
                bS[23] = r15;
                bS[24] = r16;
                bS[25] = bS[24](bS[26], bS[27]);
                bS[22] = bS[23][bS[25]];
                fS = SS[3];
                for fS, SS in SS[1], ipairs({
                    "DefaultIdle",
                    "MustacheMark",
                    "Thragg",
                    "RelaxedFly",
                    SS,
                    r15[r16(bS[1], bS[2])],
                    r15[bS[1]],
                    r15[bS[2]],
                    PS,
                    bS[1],
                    bS[2],
                    bS[3],
                    bS[4],
                    bS[5],
                    bS[6],
                    bS[7],
                    bS[8],
                    bS[9],
                    bS[10],
                    bS[11],
                    bS[12],
                    bS[13],
                    bS[14],
                    bS[15],
                    bS[16],
                    bS[17],
                    bS[18],
                    bS[19],
                    bS[20],
                    bS[21],
                    bS[22]
                }) do
                    bS[3] = "\xf6\xcdE";
                    r159 = SS;
                    bS[4] = 12339949999730;
                    bS[10] = "\xa3D\x9c";
                    bS[1] = r16;
                    bS[2] = bS[1](bS[3], bS[4]);
                    bS[4] = 12382016345733;
                    bS[3] = "h\xd8\x89\xf5\x96\x18\xba\xc7\xfak";
                    bS[1] = r16;
                    bS[2] = bS[1](bS[3], bS[4]);
                    bS[4] = 8249014603521;
                    r160 = Instance[r15[bS[2]]](r15[bS[2]]);
                    bS[1] = r16;
                    bS[3] = "\x12\xafH\x07";
                    bS[2] = bS[1](bS[3], bS[4]);
                    r160[r15[bS[2]]] = r159;
                    bS[6] = "\xa5\xcd\xad";
                    bS[7] = 21397595776748;
                    bS[4] = 33626380221738;
                    bS[3] = "]{$\x81";
                    bS[1] = r16;
                    bS[2] = bS[1](bS[3], bS[4]);
                    bS[2] = "UDim2";
                    bS[1] = Env[bS[2]];
                    bS[3] = r15;
                    bS[4] = r16;
                    bS[5] = bS[4](bS[6], bS[7]);
                    bS[2] = bS[3][bS[5]];
                    bS[3] = -8;
                    bS[7] = 10535423054633;
                    bS[2] = 1;
                    bS[4] = 0;
                    bS[5] = 50;
                    bS[1] = bS[1][bS[2]](bS[2], bS[3], bS[4], bS[5]);
                    r160[r15[bS[2]]] = bS[1];
                    bS[4] = 33057614380065;
                    bS[6] = "\tg\x81\x83\x9bq{";
                    bS[3] = "\xda\xedH\x16\xe5 \xa1\xec\x83\xdd\x8d\x16\xac\xf1\xa3\xfd";
                    bS[1] = r16;
                    bS[2] = bS[1](bS[3], bS[4]);
                    bS[2] = "Color3";
                    bS[1] = Env[bS[2]];
                    bS[3] = r15;
                    bS[4] = r16;
                    bS[5] = bS[4](bS[6], bS[7]);
                    bS[2] = bS[3][bS[5]];
                    bS[3] = 20;
                    bS[4] = 50;
                    bS[2] = 35;
                    bS[1] = bS[1][bS[2]](bS[2], bS[3], bS[4]);
                    r160[r15[bS[2]]] = bS[1];
                    bS[13] = "\xa3=\xa8s\xd1\xaew";
                    bS[3] = "\x9c\xfb\\\xe4qnu\x8a\xda\xa5\x189\x12rUj\x9b\x83X\xe9\x06V";
                    bS[4] = 21855149565889;
                    bS[1] = r16;
                    bS[2] = bS[1](bS[3], bS[4]);
                    bS[3] = "Ro\xcc\xf8";
                    r160[r15[bS[2]]] = .1;
                    bS[4] = 12157040268829;
                    bS[1] = r16;
                    bS[2] = bS[1](bS[3], bS[4]);
                    bS[4] = "";
                    bS[5] = 25299903688197;
                    bS[17] = 17159978573622;
                    bS[1] = r15;
                    bS[2] = r16;
                    bS[3] = bS[2](bS[4], bS[5]);
                    r160[r15[bS[2]]] = bS[1][bS[3]];
                    bS[7] = "\xcc\xac\xc5";
                    bS[11] = 18943401288309;
                    bS[3] = "\xfaE\x8f\x8f\xf8\xe7\xd3\xed\xf6\xb7/\xdc\x95\x16\xf6";
                    bS[4] = 27453724455408;
                    bS[1] = r16;
                    bS[2] = bS[1](bS[3], bS[4]);
                    bS[4] = 2784229737744;
                    r160[r15[bS[2]]] = false;
                    bS[1] = r16;
                    bS[3] = "t\x91\xbf\xb3\t\x93\x10#\x0f\xf8p";
                    bS[2] = bS[1](bS[3], bS[4]);
                    bS[4] = 1013127676375;
                    PS = fS;
                    r160[r15[bS[2]]] = PS;
                    bS[1] = r16;
                    bS[3] = "\x8c\xac\xb9\x95\xe4\x14";
                    bS[2] = bS[1](bS[3], bS[4]);
                    r160[r15[bS[2]]] = r105;
                    bS[14] = 27498830524933;
                    bS[5] = 27538964099607;
                    bS[1] = r15;
                    bS[4] = "k\xfdx";
                    bS[2] = r16;
                    bS[3] = bS[2](bS[4], bS[5]);
                    bS[4] = "\xd3\x0b\xae\xe3!\x01\xa5|\xe8u";
                    bS[1] = r15;
                    bS[2] = r16;
                    bS[5] = 32728387779464;
                    bS[15] = 16945456881362;
                    bS[3] = bS[2](bS[4], bS[5]);
                    bS[5] = 28977307006133;
                    r161 = Instance[bS[1][bS[3]]](bS[1][bS[3]]);
                    bS[4] = "4\x1d*\x8c\xb1";
                    bS[1] = r15;
                    bS[2] = r16;
                    bS[8] = 6732600052799;
                    bS[3] = bS[2](bS[4], bS[5]);
                    bS[3] = "ColorSequence";
                    bS[16] = 8094795648697;
                    bS[2] = Env[bS[3]];
                    bS[4] = r15;
                    bS[5] = r16;
                    bS[6] = bS[5](bS[7], bS[8]);
                    bS[3] = bS[4][bS[6]];
                    bS[1] = bS[2][bS[3]];
                    bS[6] = "ColorSequenceKeypoint";
                    bS[5] = Env[bS[6]];
                    bS[7] = r15;
                    bS[8] = r16;
                    bS[9] = bS[8](bS[10], bS[11]);
                    bS[6] = bS[7][bS[9]];
                    bS[9] = "Color3";
                    bS[4] = bS[5][bS[6]];
                    bS[6] = 0;
                    bS[8] = Env[bS[9]];
                    bS[10] = r15;
                    bS[11] = r16;
                    bS[12] = bS[11](bS[13], bS[14]);
                    bS[9] = bS[10][bS[12]];
                    bS[7] = bS[8][bS[9]];
                    bS[9] = 45;
                    bS[11] = 65;
                    bS[10] = 25;
                    bS[12] = 6086194137874;
                    bS[8] = {
                        bS[7](bS[9], bS[10], bS[11])
                    };
                    bS[7] = "ColorSequenceKeypoint";
                    bS[5] = bS[4](bS[6], x(bS[8]));
                    bS[6] = Env[bS[7]];
                    bS[8] = r15;
                    bS[9] = r16;
                    bS[11] = "[\xf0!";
                    bS[10] = bS[9](bS[11], bS[12]);
                    bS[7] = bS[8][bS[10]];
                    bS[10] = "Color3";
                    bS[4] = bS[6][bS[7]];
                    bS[9] = Env[bS[10]];
                    bS[14] = "8\xd8>\x0e\xaf\x00\xce";
                    bS[7] = .3;
                    bS[11] = r15;
                    bS[12] = r16;
                    bS[13] = bS[12](bS[14], bS[15]);
                    bS[10] = bS[11][bS[13]];
                    bS[8] = bS[9][bS[10]];
                    bS[10] = 55;
                    bS[12] = 75;
                    bS[11] = 30;
                    bS[9] = {
                        bS[8](bS[10], bS[11], bS[12])
                    };
                    bS[6] = bS[4](bS[7], x(bS[9]));
                    bS[13] = 29827418453569;
                    bS[8] = "ColorSequenceKeypoint";
                    bS[7] = Env[bS[8]];
                    bS[12] = "?\x92\x07";
                    bS[9] = r15;
                    bS[10] = r16;
                    bS[11] = bS[10](bS[12], bS[13]);
                    bS[8] = bS[9][bS[11]];
                    bS[11] = "Color3";
                    bS[4] = bS[7][bS[8]];
                    bS[10] = Env[bS[11]];
                    bS[12] = r15;
                    bS[8] = .7;
                    bS[15] = "\xf4\x07\xd9\xce\xbf\xee\x16";
                    bS[13] = r16;
                    bS[14] = bS[13](bS[15], bS[16]);
                    bS[11] = bS[12][bS[14]];
                    bS[9] = bS[10][bS[11]];
                    bS[12] = 35;
                    bS[11] = 65;
                    bS[16] = "\xfdC4\xd1){\x98";
                    bS[13] = 85;
                    bS[10] = {
                        bS[9](bS[11], bS[12], bS[13])
                    };
                    bS[7] = bS[4](bS[8], x(bS[10]));
                    bS[13] = ":\xe5\xfe";
                    bS[9] = "ColorSequenceKeypoint";
                    bS[14] = 14028160129412;
                    bS[8] = Env[bS[9]];
                    bS[10] = r15;
                    bS[11] = r16;
                    bS[12] = bS[11](bS[13], bS[14]);
                    bS[9] = bS[10][bS[12]];
                    bS[4] = bS[8][bS[9]];
                    bS[9] = 1;
                    bS[12] = "Color3";
                    bS[11] = Env[bS[12]];
                    bS[13] = r15;
                    bS[14] = r16;
                    bS[15] = bS[14](bS[16], bS[17]);
                    bS[12] = bS[13][bS[15]];
                    bS[13] = 25;
                    bS[10] = bS[11][bS[12]];
                    bS[14] = 65;
                    bS[12] = 45;
                    bS[11] = {
                        bS[10](bS[12], bS[13], bS[14])
                    };
                    bS[8] = {
                        bS[4](bS[9], x(bS[11]))
                    };
                    bS[3] = {
                        bS[5],
                        bS[6],
                        bS[7],
                        x(bS[8])
                    };
                    bS[2] = bS[1](bS[3]);
                    bS[4] = "\xc3hH\x94\xc1\x18\x9a\xf1";
                    r161[bS[1][bS[3]]] = bS[2];
                    bS[5] = 6401845480357;
                    bS[1] = r15;
                    bS[2] = r16;
                    bS[3] = bS[2](bS[4], bS[5]);
                    bS[1] = 90;
                    r161[bS[1][bS[3]]] = bS[1];
                    bS[1] = r15;
                    bS[2] = r16;
                    bS[4] = "\x95C\xadF\x89\xff";
                    bS[5] = 32869113936841;
                    bS[3] = bS[2](bS[4], bS[5]);
                    bS[5] = "\x12DN";
                    bS[1] = r160;
                    bS[6] = 26019008737108;
                    r161[bS[1][bS[3]]] = bS[1];
                    bS[1] = "Instance";
                    bS[2] = r15;
                    bS[3] = r16;
                    bS[4] = bS[3](bS[5], bS[6]);
                    bS[1] = bS[2][bS[4]];
                    bS[5] = "\x10hs\xe4`?\xffx";
                    bS[2] = r15;
                    bS[3] = r16;
                    bS[6] = 15862119062746;
                    bS[4] = bS[3](bS[5], bS[6]);
                    bS[7] = "#U\x1e";
                    bS[1] = bS[2][bS[4]];
                    PS = Env[bS[1]][bS[1]](bS[1]);
                    bS[5] = 30711424432093;
                    bS[4] = "\x90\xf8\xd5V\xd7\x8b9a\xc9\xa3\xc9\xe5";
                    bS[1] = r15;
                    bS[2] = r16;
                    bS[3] = bS[2](bS[4], bS[5]);
                    bS[9] = "E_\x8b";
                    bS[8] = 15508112366645;
                    bS[3] = "UDim";
                    bS[2] = Env[bS[3]];
                    bS[4] = r15;
                    bS[5] = r16;
                    bS[6] = bS[5](bS[7], bS[8]);
                    bS[3] = bS[4][bS[6]];
                    bS[4] = 10;
                    bS[1] = bS[2][bS[3]];
                    bS[3] = 0;
                    bS[2] = bS[1](bS[3], bS[4]);
                    PS[bS[1][bS[3]]] = bS[2];
                    bS[5] = 28202069062476;
                    bS[6] = "\xd0\xf7\xa3";
                    bS[1] = r15;
                    bS[4] = "\xc5g9:\x11\xe9";
                    bS[7] = 7909068688994;
                    bS[10] = 29306664465742;
                    bS[2] = r16;
                    bS[3] = bS[2](bS[4], bS[5]);
                    bS[1] = r160;
                    bS[2] = "Instance";
                    PS[bS[1][bS[3]]] = bS[1];
                    bS[1] = Env[bS[2]];
                    bS[3] = r15;
                    bS[4] = r16;
                    bS[5] = bS[4](bS[6], bS[7]);
                    bS[2] = bS[3][bS[5]];
                    bS[3] = r15;
                    bS[7] = 23757126970166;
                    bS[4] = r16;
                    bS[6] = "}\xbb*\\\xba\x14K\x8c\x1a\xa2";
                    bS[5] = bS[4](bS[6], bS[7]);
                    bS[2] = bS[3][bS[5]];
                    bS[1] = bS[1][bS[2]](bS[2]);
                    r162 = bS[1];
                    bS[1] = r162;
                    bS[7] = 26644077178999;
                    bS[6] = "}\x90!\xd6";
                    bS[3] = r15;
                    bS[4] = r16;
                    bS[5] = bS[4](bS[6], bS[7]);
                    bS[2] = bS[3][bS[5]];
                    bS[5] = "UDim2";
                    bS[4] = Env[bS[5]];
                    bS[6] = r15;
                    bS[7] = r16;
                    bS[8] = bS[7](bS[9], bS[10]);
                    bS[7] = 1;
                    bS[5] = bS[6][bS[8]];
                    bS[8] = 10;
                    bS[6] = 10;
                    bS[10] = 1995128144801;
                    bS[3] = bS[4][bS[5]];
                    bS[5] = 1;
                    bS[4] = bS[3](bS[5], bS[6], bS[7], bS[8]);
                    bS[1][bS[2]] = bS[4];
                    bS[1] = r162;
                    bS[6] = "\xa8L\xf0\x11\xed\xf71f";
                    bS[7] = 21630369245016;
                    bS[3] = r15;
                    bS[4] = r16;
                    bS[5] = bS[4](bS[6], bS[7]);
                    bS[2] = bS[3][bS[5]];
                    bS[5] = "UDim2";
                    bS[11] = 34115654942222;
                    bS[4] = Env[bS[5]];
                    bS[6] = r15;
                    bS[9] = "\x96.X";
                    bS[7] = r16;
                    bS[8] = bS[7](bS[9], bS[10]);
                    bS[10] = 1387267146373;
                    bS[7] = 0;
                    bS[5] = bS[6][bS[8]];
                    bS[3] = bS[4][bS[5]];
                    bS[5] = 0;
                    bS[8] = -5;
                    bS[6] = -5;
                    bS[4] = bS[3](bS[5], bS[6], bS[7], bS[8]);
                    bS[1][bS[2]] = bS[4];
                    bS[1] = r162;
                    bS[7] = 15977441926416;
                    bS[6] = "W\xdc\x0e\x87\rX\xd04`l7U\xb0\xdcY)\x16f3\xa1<\xd4";
                    bS[3] = r15;
                    bS[4] = r16;
                    bS[5] = bS[4](bS[6], bS[7]);
                    bS[2] = bS[3][bS[5]];
                    bS[8] = 27295031832998;
                    bS[3] = 1;
                    bS[7] = 33787409513845;
                    bS[1][bS[2]] = bS[3];
                    bS[1] = r162;
                    bS[3] = r15;
                    bS[4] = r16;
                    bS[6] = "+\x9f\x06\xad2";
                    bS[5] = bS[4](bS[6], bS[7]);
                    bS[2] = bS[3][bS[5]];
                    bS[7] = "b\xb2d'\xfc\xb9X\xd3l\xeb\xf1\xdb\x8c\xdd\x98\xadn\xbb\x06U\xf8\xee\x1f";
                    bS[4] = r15;
                    bS[5] = r16;
                    bS[6] = bS[5](bS[7], bS[8]);
                    bS[3] = bS[4][bS[6]];
                    bS[1][bS[2]] = bS[3];
                    bS[7] = 8246794276608;
                    bS[9] = "\x00\xdf\xe13Z\x0eu";
                    bS[6] = "R%\xce\x88\xe7e\xcd\xbe\x00\x92\x0e";
                    bS[1] = r162;
                    bS[3] = r15;
                    bS[4] = r16;
                    bS[5] = bS[4](bS[6], bS[7]);
                    bS[2] = bS[3][bS[5]];
                    bS[5] = "Color3";
                    bS[4] = Env[bS[5]];
                    bS[6] = r15;
                    bS[7] = r16;
                    bS[8] = bS[7](bS[9], bS[10]);
                    bS[5] = bS[6][bS[8]];
                    bS[7] = 160;
                    bS[3] = bS[4][bS[5]];
                    bS[5] = 100;
                    bS[6] = 60;
                    bS[4] = bS[3](bS[5], bS[6], bS[7]);
                    bS[6] = "_\xf7\x11\xc8P\xb9[\x10\xf2|\xc2\x1f?\x83\x9d}\xf6";
                    bS[1][bS[2]] = bS[4];
                    bS[1] = r162;
                    bS[7] = 28308159509374;
                    bS[3] = r15;
                    bS[4] = r16;
                    bS[5] = bS[4](bS[6], bS[7]);
                    bS[2] = bS[3][bS[5]];
                    bS[10] = "\xdb\x92\x0eJ\x03S\"\xbch";
                    bS[3] = .8;
                    bS[1][bS[2]] = bS[3];
                    bS[7] = 601386271000;
                    bS[1] = r162;
                    bS[6] = "\xc5\xcf\x9c\xa6?y\xd3`\x9d";
                    bS[3] = r15;
                    bS[4] = r16;
                    bS[5] = bS[4](bS[6], bS[7]);
                    bS[2] = bS[3][bS[5]];
                    bS[6] = "Enum";
                    bS[5] = Env[bS[6]];
                    bS[7] = r15;
                    bS[8] = r16;
                    bS[9] = bS[8](bS[10], bS[11]);
                    bS[6] = bS[7][bS[9]];
                    bS[10] = 22101094410291;
                    bS[4] = bS[5][bS[6]];
                    bS[6] = r15;
                    bS[9] = "b\xb5&\xf3h";
                    bS[7] = r16;
                    bS[8] = bS[7](bS[9], bS[10]);
                    bS[5] = bS[6][bS[8]];
                    bS[3] = bS[4][bS[5]];
                    bS[9] = "\x12+\xf0";
                    bS[1][bS[2]] = bS[3];
                    bS[1] = r162;
                    bS[7] = 7333986323799;
                    bS[3] = r15;
                    bS[6] = "\xf5\xcc\xea7\x8f5\xbe \xeaJ\xa7";
                    bS[4] = r16;
                    bS[10] = 17874684125315;
                    bS[5] = bS[4](bS[6], bS[7]);
                    bS[2] = bS[3][bS[5]];
                    bS[5] = "Rect";
                    bS[4] = Env[bS[5]];
                    bS[6] = r15;
                    bS[7] = r16;
                    bS[8] = bS[7](bS[9], bS[10]);
                    bS[7] = 276;
                    bS[5] = bS[6][bS[8]];
                    bS[3] = bS[4][bS[5]];
                    bS[5] = 24;
                    bS[8] = 276;
                    bS[6] = 24;
                    bS[4] = bS[3](bS[5], bS[6], bS[7], bS[8]);
                    bS[6] = "\xe2\x15\xae:\xf0\xf1";
                    bS[1][bS[2]] = bS[4];
                    bS[7] = 14415552846392;
                    bS[1] = r162;
                    bS[3] = r15;
                    bS[4] = r16;
                    bS[5] = bS[4](bS[6], bS[7]);
                    bS[2] = bS[3][bS[5]];
                    bS[3] = -1;
                    bS[6] = "\x02\xf3i\xdb'Z";
                    bS[1][bS[2]] = bS[3];
                    bS[1] = r162;
                    bS[3] = r15;
                    bS[4] = r16;
                    bS[7] = 13420180478057;
                    bS[5] = bS[4](bS[6], bS[7]);
                    bS[2] = bS[3][bS[5]];
                    bS[3] = r160;
                    bS[1][bS[2]] = bS[3];
                    bS[7] = "\xef\x14q";
                    bS[3] = "Instance";
                    bS[8] = 34820141023062;
                    bS[2] = Env[bS[3]];
                    bS[4] = r15;
                    bS[5] = r16;
                    bS[6] = bS[5](bS[7], bS[8]);
                    bS[3] = bS[4][bS[6]];
                    bS[1] = bS[2][bS[3]];
                    bS[4] = r15;
                    bS[7] = "\xcd\xe1\x1f\x9a\x1f";
                    bS[5] = r16;
                    bS[9] = "\x81\xac\r";
                    bS[8] = 9058599194746;
                    bS[6] = bS[5](bS[7], bS[8]);
                    bS[8] = 13663929047258;
                    bS[3] = bS[4][bS[6]];
                    bS[6] = "W\x86q\xa8";
                    bS[2] = bS[1](bS[3]);
                    bS[3] = r15;
                    bS[7] = 21514976126754;
                    bS[4] = r16;
                    bS[5] = bS[4](bS[6], bS[7]);
                    bS[7] = "m\rQ\xf7\xc96T\x86\x0f\xf3.\xa2\xc9U\x98(\xf8e";
                    bS[1] = bS[3][bS[5]];
                    bS[10] = 27916821607111;
                    bS[4] = r15;
                    bS[5] = r16;
                    bS[6] = bS[5](bS[7], bS[8]);
                    bS[3] = bS[4][bS[6]];
                    bS[6] = "\x99J;x";
                    bS[2][bS[1]] = bS[3];
                    bS[3] = r15;
                    bS[7] = 26218577768368;
                    bS[4] = r16;
                    bS[5] = bS[4](bS[6], bS[7]);
                    bS[1] = bS[3][bS[5]];
                    bS[5] = "UDim2";
                    bS[4] = Env[bS[5]];
                    bS[6] = r15;
                    bS[7] = r16;
                    bS[8] = bS[7](bS[9], bS[10]);
                    bS[5] = bS[6][bS[8]];
                    bS[3] = bS[4][bS[5]];
                    bS[7] = .6;
                    bS[8] = 0;
                    bS[6] = 0;
                    bS[5] = .03;
                    bS[4] = bS[3](bS[5], bS[6], bS[7], bS[8]);
                    bS[2][bS[1]] = bS[4];
                    bS[6] = "\xb4\x8ea\x92\x18\xc7$\x82";
                    bS[7] = 11348670895268;
                    bS[3] = r15;
                    bS[10] = 17053214400261;
                    bS[4] = r16;
                    bS[9] = "\xb2\xc6\x82";
                    bS[5] = bS[4](bS[6], bS[7]);
                    bS[1] = bS[3][bS[5]];
                    bS[5] = "UDim2";
                    bS[4] = Env[bS[5]];
                    bS[6] = r15;
                    bS[7] = r16;
                    bS[8] = bS[7](bS[9], bS[10]);
                    bS[5] = bS[6][bS[8]];
                    bS[8] = 0;
                    bS[6] = 0;
                    bS[3] = bS[4][bS[5]];
                    bS[5] = .01;
                    bS[7] = .2;
                    bS[4] = bS[3](bS[5], bS[6], bS[7], bS[8]);
                    bS[2][bS[1]] = bS[4];
                    bS[3] = r15;
                    bS[4] = r16;
                    bS[6] = "\xce\xef\xc4\xb4<'&;G\xfc\x970\xf2\x8a\xea\xe9";
                    bS[7] = 8594568564642;
                    bS[5] = bS[4](bS[6], bS[7]);
                    bS[4] = false;
                    bS[6] = false;
                    bS[1] = bS[3][bS[5]];
                    bS[8] = r159;
                    bS[9] = r64;
                    bS[7] = bS[8] == bS[9];
                    bS[5] = bS[7];
                    if bS[7] then
                        bS[9] = "Color3";
                        bS[8] = Env[bS[9]];
                        bS[13] = "G\xdah\xa3X;q";
                        bS[14] = 6875723222145;
                        bS[10] = r15;
                        bS[11] = r16;
                        bS[12] = bS[11](bS[13], bS[14]);
                        bS[9] = bS[10][bS[12]];
                        bS[11] = 230;
                        bS[7] = bS[8][bS[9]];
                        bS[9] = 180;
                        bS[10] = 130;
                        bS[8] = bS[7](bS[9], bS[10], bS[11]);
                        bS[5] = bS[8];
                    end;
                    v8 = bS[6];
                    bS[3] = bS[5];
                    if bS[5] then
                        bS[9] = 14784791911140;
                        bS[6] = "\xa52!M\xa5z";
                        bS[7] = 1612265538286;
                        bS[2][bS[1]] = bS[3];
                        bS[13] = 19302501475100;
                        bS[3] = r15;
                        v8 = bS[4];
                        bS[4] = r16;
                        bS[5] = bS[4](bS[6], bS[7]);
                        bS[4] = "Instance";
                        bS[1] = bS[3][bS[5]];
                        bS[3] = r160;
                        bS[2][bS[1]] = bS[3];
                        bS[3] = Env[bS[4]];
                        bS[5] = r15;
                        bS[10] = "Y\x82,";
                        bS[8] = "\xfa\x9cG";
                        bS[6] = r16;
                        bS[7] = bS[6](bS[8], bS[9]);
                        bS[9] = 21134081648241;
                        bS[4] = bS[5][bS[7]];
                        bS[8] = "\x9e\x8dog\xa6D\x1e&";
                        bS[11] = 8907084271667;
                        bS[1] = bS[3][bS[4]];
                        bS[5] = r15;
                        bS[6] = r16;
                        bS[7] = bS[6](bS[8], bS[9]);
                        bS[8] = 28256342717285;
                        bS[4] = bS[5][bS[7]];
                        bS[3] = bS[1](bS[4]);
                        bS[4] = r15;
                        bS[7] = "\xe3@\x17\xb5\xb8{\xe0(\xe4\xc1\x8a.";
                        bS[5] = r16;
                        bS[6] = bS[5](bS[7], bS[8]);
                        bS[1] = bS[4][bS[6]];
                        bS[6] = "UDim";
                        bS[5] = Env[bS[6]];
                        bS[14] = 31341167098114;
                        bS[7] = r15;
                        bS[8] = r16;
                        bS[9] = bS[8](bS[10], bS[11]);
                        bS[12] = 22362130589869;
                        bS[10] = 30251470862086;
                        bS[6] = bS[7][bS[9]];
                        bS[4] = bS[5][bS[6]];
                        bS[11] = "\r\x1c<";
                        bS[7] = 0;
                        bS[8] = 7580078788041;
                        bS[6] = 0.5;
                        bS[5] = bS[4](bS[6], bS[7]);
                        bS[7] = "\x04\xe8\xf01Z\xb2";
                        bS[3][bS[1]] = bS[5];
                        bS[4] = r15;
                        bS[5] = r16;
                        bS[6] = bS[5](bS[7], bS[8]);
                        bS[1] = bS[4][bS[6]];
                        bS[5] = "Instance";
                        bS[4] = bS[2];
                        bS[3][bS[1]] = bS[4];
                        bS[9] = "U\n\xfb";
                        bS[4] = Env[bS[5]];
                        bS[21] = 26199386746792;
                        bS[6] = r15;
                        bS[7] = r16;
                        bS[8] = bS[7](bS[9], bS[10]);
                        bS[9] = "\xd1:G\xb0\xaes\x98\xbe[x";
                        bS[5] = bS[6][bS[8]];
                        bS[1] = bS[4][bS[5]];
                        bS[6] = r15;
                        bS[7] = r16;
                        bS[10] = 24884526214467;
                        bS[8] = bS[7](bS[9], bS[10]);
                        bS[5] = bS[6][bS[8]];
                        bS[9] = 6183116213055;
                        bS[4] = bS[1](bS[5]);
                        bS[5] = r15;
                        bS[6] = r16;
                        bS[8] = "\x92?7b";
                        bS[7] = bS[6](bS[8], bS[9]);
                        bS[1] = bS[5][bS[7]];
                        bS[7] = "UDim2";
                        bS[6] = Env[bS[7]];
                        bS[8] = r15;
                        bS[9] = r16;
                        bS[10] = bS[9](bS[11], bS[12]);
                        bS[17] = 9288388727013;
                        bS[9] = 1;
                        bS[7] = bS[8][bS[10]];
                        bS[5] = bS[6][bS[7]];
                        bS[8] = 6;
                        bS[10] = 6;
                        bS[7] = 1;
                        bS[6] = bS[5](bS[7], bS[8], bS[9], bS[10]);
                        bS[11] = "x\xb7\xcf";
                        bS[4][bS[1]] = bS[6];
                        bS[5] = r15;
                        bS[12] = 7570383359429;
                        bS[6] = r16;
                        bS[9] = 33131320491075;
                        bS[8] = "lim\xf2\xa8)\xc4\xce";
                        bS[7] = bS[6](bS[8], bS[9]);
                        bS[1] = bS[5][bS[7]];
                        bS[7] = "UDim2";
                        bS[6] = Env[bS[7]];
                        bS[8] = r15;
                        bS[9] = r16;
                        bS[10] = bS[9](bS[11], bS[12]);
                        bS[9] = 0;
                        bS[7] = bS[8][bS[10]];
                        bS[5] = bS[6][bS[7]];
                        bS[8] = -3;
                        bS[10] = -3;
                        bS[7] = 0;
                        bS[6] = bS[5](bS[7], bS[8], bS[9], bS[10]);
                        bS[8] = "#\x9f\x9f\x7fX\x08`\xf1@K*\x89Rt\xac\x8az\xe8\xc3\\\xb0\\";
                        bS[4][bS[1]] = bS[6];
                        bS[10] = 6501666196435;
                        bS[5] = r15;
                        bS[6] = r16;
                        bS[9] = 15485917994027;
                        bS[7] = bS[6](bS[8], bS[9]);
                        bS[1] = bS[5][bS[7]];
                        bS[5] = 1;
                        bS[9] = 33732706778460;
                        bS[4][bS[1]] = bS[5];
                        bS[8] = "+J%T?";
                        bS[5] = r15;
                        bS[6] = r16;
                        bS[7] = bS[6](bS[8], bS[9]);
                        bS[1] = bS[5][bS[7]];
                        bS[6] = r15;
                        bS[9] = "\xd7\x15=\xee\xc5\xe5\x15\xf8\x12\x04\x01/q\xb4\xa0}\x17t\xe9vJ!2";
                        bS[7] = r16;
                        bS[8] = bS[7](bS[9], bS[10]);
                        bS[5] = bS[6][bS[8]];
                        bS[8] = "\x83#\x9c\x12KOt\xe6\xff\x08\t";
                        bS[12] = 5882320997043;
                        bS[11] = "jYkN\xd1\xf7\xb8";
                        bS[4][bS[1]] = bS[5];
                        bS[9] = 2402640315486;
                        bS[5] = r15;
                        bS[6] = r16;
                        bS[7] = bS[6](bS[8], bS[9]);
                        bS[1] = bS[5][bS[7]];
                        bS[7] = "Color3";
                        bS[6] = Env[bS[7]];
                        bS[8] = r15;
                        bS[9] = r16;
                        bS[10] = bS[9](bS[11], bS[12]);
                        bS[9] = 250;
                        bS[7] = bS[8][bS[10]];
                        bS[5] = bS[6][bS[7]];
                        bS[7] = 200;
                        bS[8] = 150;
                        bS[6] = bS[5](bS[7], bS[8], bS[9]);
                        bS[4][bS[1]] = bS[6];
                        bS[5] = r15;
                        bS[6] = r16;
                        bS[8] = "\x027\xb0\xcf:\xb7\x89\xee\xd2_\x9f=\xfc\xda\xf7;\x06";
                        bS[9] = 24376350338135;
                        bS[7] = bS[6](bS[8], bS[9]);
                        bS[1] = bS[5][bS[7]];
                        bS[5] = .7;
                        bS[4][bS[1]] = bS[5];
                        bS[12] = "\x88\x94R\x0b\xce\x14Q\xa1\xa0";
                        bS[5] = r15;
                        bS[9] = 16818193161879;
                        bS[8] = "3\x9d\x01\xfb\\y\x8fE\x92";
                        bS[6] = r16;
                        bS[7] = bS[6](bS[8], bS[9]);
                        bS[8] = "Enum";
                        bS[1] = bS[5][bS[7]];
                        bS[7] = Env[bS[8]];
                        bS[9] = r15;
                        bS[10] = r16;
                        bS[11] = bS[10](bS[12], bS[13]);
                        bS[8] = bS[9][bS[11]];
                        bS[6] = bS[7][bS[8]];
                        bS[12] = 24012119255981;
                        bS[8] = r15;
                        bS[20] = 26236939595705;
                        bS[9] = r16;
                        bS[11] = "FN\xc4 I";
                        bS[10] = bS[9](bS[11], bS[12]);
                        bS[7] = bS[8][bS[10]];
                        bS[5] = bS[6][bS[7]];
                        bS[4][bS[1]] = bS[5];
                        bS[9] = 25876792356625;
                        bS[11] = "\x8f\n\xfc";
                        bS[8] = "uI\x89'\x92~7V;u\x1e";
                        bS[5] = r15;
                        bS[6] = r16;
                        bS[7] = bS[6](bS[8], bS[9]);
                        bS[1] = bS[5][bS[7]];
                        bS[7] = "Rect";
                        bS[12] = 5633105496639;
                        bS[6] = Env[bS[7]];
                        bS[8] = r15;
                        bS[9] = r16;
                        bS[10] = bS[9](bS[11], bS[12]);
                        bS[9] = 276;
                        bS[7] = bS[8][bS[10]];
                        bS[8] = 24;
                        bS[10] = 276;
                        bS[5] = bS[6][bS[7]];
                        bS[7] = 24;
                        bS[6] = bS[5](bS[7], bS[8], bS[9], bS[10]);
                        bS[4][bS[1]] = bS[6];
                        bS[8] = "sz\x13h\xf4<";
                        bS[5] = r15;
                        bS[9] = 2491676198024;
                        bS[6] = r16;
                        bS[7] = bS[6](bS[8], bS[9]);
                        bS[8] = "19\xa74?\x0c";
                        bS[1] = bS[5][bS[7]];
                        bS[3] = nil;
                        bS[5] = -1;
                        bS[4][bS[1]] = bS[5];
                        bS[5] = r15;
                        bS[9] = 16910998019778;
                        bS[6] = r16;
                        bS[7] = bS[6](bS[8], bS[9]);
                        bS[1] = bS[5][bS[7]];
                        bS[5] = bS[2];
                        bS[6] = "Instance";
                        bS[4][bS[1]] = bS[5];
                        bS[5] = Env[bS[6]];
                        bS[7] = r15;
                        bS[15] = 31054071658620;
                        bS[10] = "\x84\xe1\xe4";
                        bS[8] = r16;
                        bS[11] = 33549927103750;
                        bS[9] = bS[8](bS[10], bS[11]);
                        bS[10] = "\xe0s\xf1\xe4\x7fPr\x1b\xc2";
                        bS[6] = bS[7][bS[9]];
                        bS[11] = 13840347093292;
                        bS[1] = bS[5][bS[6]];
                        bS[7] = r15;
                        bS[8] = r16;
                        bS[9] = bS[8](bS[10], bS[11]);
                        bS[6] = bS[7][bS[9]];
                        bS[5] = bS[1](bS[6]);
                        bS[11] = 33964212436423;
                        bS[1] = 147;
                        o[bS[1]] = bS[5];
                        bS[5] = o[bS[1]];
                        bS[10] = "G\xbf\x0e\xd8";
                        bS[7] = r15;
                        bS[8] = r16;
                        bS[12] = 6960123579561;
                        bS[9] = bS[8](bS[10], bS[11]);
                        bS[6] = bS[7][bS[9]];
                        bS[8] = r15;
                        bS[9] = r16;
                        bS[11] = "\nQA\xd2\xefQ\xea!\x80";
                        bS[10] = bS[9](bS[11], bS[12]);
                        bS[7] = bS[8][bS[10]];
                        bS[11] = 20716070331822;
                        bS[16] = "\xeb7\xe9";
                        bS[5][bS[6]] = bS[7];
                        bS[13] = "\r3\x8a";
                        bS[10] = "\x0b)f\xf1";
                        bS[5] = o[bS[1]];
                        bS[7] = r15;
                        bS[8] = r16;
                        bS[9] = bS[8](bS[10], bS[11]);
                        bS[6] = bS[7][bS[9]];
                        bS[9] = "UDim2";
                        bS[8] = Env[bS[9]];
                        bS[10] = r15;
                        bS[11] = r16;
                        bS[12] = bS[11](bS[13], bS[14]);
                        bS[11] = .8;
                        bS[9] = bS[10][bS[12]];
                        bS[10] = 0;
                        bS[7] = bS[8][bS[9]];
                        bS[12] = 0;
                        bS[9] = .9;
                        bS[8] = bS[7](bS[9], bS[10], bS[11], bS[12]);
                        bS[5][bS[6]] = bS[8];
                        bS[10] = "\xfb\xb6\xb9O\xc6\x7f`\x01";
                        bS[5] = o[bS[1]];
                        bS[11] = 8572389117847;
                        bS[7] = r15;
                        bS[8] = r16;
                        bS[9] = bS[8](bS[10], bS[11]);
                        bS[14] = 316490137747;
                        bS[6] = bS[7][bS[9]];
                        bS[9] = "UDim2";
                        bS[8] = Env[bS[9]];
                        bS[10] = r15;
                        bS[11] = r16;
                        bS[13] = "\xcf\x94\xbc";
                        bS[12] = bS[11](bS[13], bS[14]);
                        bS[11] = .1;
                        bS[9] = bS[10][bS[12]];
                        bS[7] = bS[8][bS[9]];
                        bS[14] = 24870955445565;
                        bS[12] = 0;
                        bS[10] = 0;
                        bS[9] = .08;
                        bS[8] = bS[7](bS[9], bS[10], bS[11], bS[12]);
                        bS[5][bS[6]] = bS[8];
                        bS[5] = o[bS[1]];
                        bS[7] = r15;
                        bS[19] = "\x02\xfdV\xde,\x8c\xbd";
                        bS[8] = r16;
                        bS[11] = 17290876641139;
                        bS[10] = "u\xa3\x92\xa3\xae\xe5\xf6R\xbbd\xf3L}\xec\xad\xbc\xa8%34\xd8\xe2";
                        bS[9] = bS[8](bS[10], bS[11]);
                        bS[13] = "B\x9a?n\xdfM\x81";
                        bS[6] = bS[7][bS[9]];
                        bS[7] = 1;
                        bS[5][bS[6]] = bS[7];
                        bS[5] = o[bS[1]];
                        bS[10] = "\xad\x83Cz";
                        bS[11] = 1644359729917;
                        bS[7] = r15;
                        bS[8] = r16;
                        bS[9] = bS[8](bS[10], bS[11]);
                        bS[6] = bS[7][bS[9]];
                        bS[7] = r159;
                        bS[5][bS[6]] = bS[7];
                        bS[5] = o[bS[1]];
                        bS[10] = "\xe6.\xd5\xcc\xc1\xcd\x8d*\x85\xca";
                        bS[7] = r15;
                        bS[8] = r16;
                        bS[11] = 9223574425799;
                        bS[9] = bS[8](bS[10], bS[11]);
                        bS[6] = bS[7][bS[9]];
                        bS[9] = "Color3";
                        bS[8] = Env[bS[9]];
                        bS[10] = r15;
                        bS[11] = r16;
                        bS[12] = bS[11](bS[13], bS[14]);
                        bS[11] = 255;
                        bS[9] = bS[10][bS[12]];
                        bS[7] = bS[8][bS[9]];
                        bS[9] = 255;
                        bS[10] = 255;
                        bS[8] = bS[7](bS[9], bS[10], bS[11]);
                        bS[5][bS[6]] = bS[8];
                        bS[10] = "E;\x88\n8,P\x87";
                        bS[11] = 31895830608388;
                        bS[5] = o[bS[1]];
                        bS[7] = r15;
                        bS[2] = nil;
                        bS[8] = r16;
                        bS[9] = bS[8](bS[10], bS[11]);
                        bS[6] = bS[7][bS[9]];
                        bS[10] = "\x9cF\x9b\x1a\xb1\xa9I\x04\xec\xb9\xe5`\x8c\xd8";
                        bS[7] = 14;
                        bS[14] = "\xe2VT6F\xc0\x8f3Hjr0\xbe,";
                        bS[5][bS[6]] = bS[7];
                        bS[5] = o[bS[1]];
                        bS[11] = 34108100640266;
                        bS[7] = r15;
                        bS[8] = r16;
                        bS[9] = bS[8](bS[10], bS[11]);
                        bS[6] = bS[7][bS[9]];
                        bS[10] = "Enum";
                        bS[9] = Env[bS[10]];
                        bS[11] = r15;
                        bS[12] = r16;
                        bS[13] = bS[12](bS[14], bS[15]);
                        bS[10] = bS[11][bS[13]];
                        bS[14] = 19073589093041;
                        bS[8] = bS[9][bS[10]];
                        bS[13] = "=\x97\xa3g";
                        bS[10] = r15;
                        bS[11] = r16;
                        bS[12] = bS[11](bS[13], bS[14]);
                        bS[9] = bS[10][bS[12]];
                        bS[7] = bS[8][bS[9]];
                        bS[5][bS[6]] = bS[7];
                        bS[5] = o[bS[1]];
                        bS[15] = 3440082912833;
                        bS[11] = 32055049026126;
                        bS[7] = r15;
                        bS[10] = "\x8d\\\xf3\xb6";
                        bS[8] = r16;
                        bS[9] = bS[8](bS[10], bS[11]);
                        bS[6] = bS[7][bS[9]];
                        bS[10] = "Enum";
                        bS[14] = "\xfa\x8d\xe9\xac";
                        bS[9] = Env[bS[10]];
                        bS[11] = r15;
                        bS[12] = r16;
                        bS[13] = bS[12](bS[14], bS[15]);
                        bS[10] = bS[11][bS[13]];
                        bS[14] = 34559507103453;
                        bS[8] = bS[9][bS[10]];
                        bS[13] = "\x8a\xe6\xfa\xbd\x80PV\n:?T\x05";
                        bS[10] = r15;
                        bS[11] = r16;
                        bS[12] = bS[11](bS[13], bS[14]);
                        bS[9] = bS[10][bS[12]];
                        bS[7] = bS[8][bS[9]];
                        bS[5][bS[6]] = bS[7];
                        bS[5] = o[bS[1]];
                        bS[7] = r15;
                        bS[8] = r16;
                        bS[11] = 30603383699370;
                        bS[10] = "\x15\x15\xd5p\xea+\xf51_,N\xeeu\xa5=\x86";
                        bS[9] = bS[8](bS[10], bS[11]);
                        bS[13] = "\x14=pm\xb74\xc1";
                        bS[6] = bS[7][bS[9]];
                        bS[14] = 9941749125653;
                        bS[9] = "Color3";
                        bS[8] = Env[bS[9]];
                        bS[10] = r15;
                        bS[11] = r16;
                        bS[12] = bS[11](bS[13], bS[14]);
                        bS[9] = bS[10][bS[12]];
                        bS[7] = bS[8][bS[9]];
                        bS[12] = 34318099463788;
                        bS[11] = 120;
                        bS[10] = 40;
                        bS[9] = 80;
                        bS[8] = bS[7](bS[9], bS[10], bS[11]);
                        bS[5][bS[6]] = bS[8];
                        bS[11] = 1777775313723;
                        bS[5] = o[bS[1]];
                        bS[7] = r15;
                        bS[8] = r16;
                        bS[10] = "\xbf\xaf'i\xa2\xb1\xc2\xe2\xc0gX\x02\xd0\xf7K\xd5\xde\xe60\x99\xf8W";
                        bS[9] = bS[8](bS[10], bS[11]);
                        bS[11] = 1301332607581;
                        bS[6] = bS[7][bS[9]];
                        bS[7] = .8;
                        bS[5][bS[6]] = bS[7];
                        bS[5] = o[bS[1]];
                        bS[7] = r15;
                        bS[8] = r16;
                        bS[10] = "l\xcf\xc1\x01@\x07";
                        bS[9] = bS[8](bS[10], bS[11]);
                        bS[11] = "o\x12\x04";
                        bS[6] = bS[7][bS[9]];
                        bS[7] = r160;
                        bS[5][bS[6]] = bS[7];
                        bS[7] = "Instance";
                        bS[6] = Env[bS[7]];
                        bS[8] = r15;
                        bS[9] = r16;
                        bS[10] = bS[9](bS[11], bS[12]);
                        bS[11] = "/T\xaa\xaf*\x8ep\x0cD\xfc";
                        bS[13] = "=x\xf3";
                        bS[12] = 18595968475603;
                        bS[14] = 23145846614554;
                        bS[7] = bS[8][bS[10]];
                        bS[5] = bS[6][bS[7]];
                        bS[8] = r15;
                        bS[9] = r16;
                        bS[10] = bS[9](bS[11], bS[12]);
                        bS[7] = bS[8][bS[10]];
                        bS[11] = 20603834082682;
                        bS[6] = bS[5](bS[7]);
                        bS[7] = r15;
                        bS[8] = r16;
                        bS[10] = "O\xdd0|H";
                        bS[9] = bS[8](bS[10], bS[11]);
                        bS[5] = bS[7][bS[9]];
                        bS[9] = "ColorSequence";
                        bS[8] = Env[bS[9]];
                        bS[10] = r15;
                        bS[11] = r16;
                        bS[12] = bS[11](bS[13], bS[14]);
                        bS[9] = bS[10][bS[12]];
                        bS[12] = "ColorSequenceKeypoint";
                        bS[7] = bS[8][bS[9]];
                        bS[11] = Env[bS[12]];
                        bS[13] = r15;
                        bS[14] = r16;
                        bS[15] = bS[14](bS[16], bS[17]);
                        bS[12] = bS[13][bS[15]];
                        bS[10] = bS[11][bS[12]];
                        bS[15] = "Color3";
                        bS[12] = 0;
                        bS[14] = Env[bS[15]];
                        bS[16] = r15;
                        bS[17] = r16;
                        bS[18] = bS[17](bS[19], bS[20]);
                        bS[17] = 250;
                        bS[20] = "\x99\xd3Kgk\x10J";
                        bS[15] = bS[16][bS[18]];
                        bS[16] = 190;
                        bS[13] = bS[14][bS[15]];
                        bS[15] = 220;
                        bS[14] = {
                            bS[13](bS[15], bS[16], bS[17])
                        };
                        bS[11] = bS[10](bS[12], x(bS[14]));
                        bS[13] = "ColorSequenceKeypoint";
                        bS[17] = "C\xde\xda";
                        bS[18] = 25637522812578;
                        bS[12] = Env[bS[13]];
                        bS[14] = r15;
                        bS[15] = r16;
                        bS[16] = bS[15](bS[17], bS[18]);
                        bS[13] = bS[14][bS[16]];
                        bS[10] = bS[12][bS[13]];
                        bS[13] = 1;
                        bS[16] = "Color3";
                        bS[15] = Env[bS[16]];
                        bS[17] = r15;
                        bS[18] = r16;
                        bS[19] = bS[18](bS[20], bS[21]);
                        bS[16] = bS[17][bS[19]];
                        bS[17] = 170;
                        bS[14] = bS[15][bS[16]];
                        bS[18] = 230;
                        bS[16] = 200;
                        bS[15] = {
                            bS[14](bS[16], bS[17], bS[18])
                        };
                        bS[12] = {
                            bS[10](bS[13], x(bS[15]))
                        };
                        bS[9] = {
                            bS[11],
                            x(bS[12])
                        };
                        bS[11] = 24602494594240;
                        bS[10] = ")\x14\x0f5W\x96";
                        bS[8] = bS[7](bS[9]);
                        bS[6][bS[5]] = bS[8];
                        bS[7] = r15;
                        bS[8] = r16;
                        bS[9] = bS[8](bS[10], bS[11]);
                        bS[5] = bS[7][bS[9]];
                        bS[7] = o[bS[1]];
                        bS[4] = nil;
                        bS[6][bS[5]] = bS[7];
                        bS[7] = r160;
                        bS[13] = 4293497817039;
                        bS[9] = r15;
                        bS[10] = r16;
                        bS[12] = "\xa8\x82u\xd2\x07h]\x17\xba\x8d";
                        bS[11] = bS[10](bS[12], bS[13]);
                        bS[8] = bS[9][bS[11]];
                        bS[5] = bS[7][bS[8]];
                        bS[13] = 3306453435907;
                        bS[7] = "Connect";
                        bS[8] = function(...)
                            v3 = r64 ~= r159 and r47;
                            if v3 then
                                v8 = r27;
                                v3 = v8.Create(v8, r160, TweenInfo.new(.3), {
                                    ["BackgroundTransparency"] = .05,
                                    ["Size"] = UDim2.new(1, -4, 0, 52)
                                });
                                v3.Play(v3);
                                v8 = r27;
                                v3 = v8.Create(v8, r161, TweenInfo.new(.3), {
                                    ["Rotation"] = 270
                                });
                                v3.Play(v3);
                                v8 = r27;
                                v3 = v8.Create(v8, r162, TweenInfo.new(.3), {
                                    ["ImageTransparency"] = .6
                                });
                                v3.Play(v3);
                                v8 = r27;
                                v3 = v8.Create(v8, o[bS[1]], TweenInfo.new(.3), {
                                    ["TextStrokeTransparency"] = .6
                                });
                                v3.Play(v3);
                            end;
                            return; 
                        end;
                        bS[7] = bS[5][bS[7]];
                        bS[7] = bS[7](bS[5], bS[8]);
                        bS[12] = "\xc5 h\xfc\xc7J\xce\xde7\xfb";
                        bS[7] = r160;
                        bS[9] = r15;
                        bS[10] = r16;
                        bS[11] = bS[10](bS[12], bS[13]);
                        bS[13] = 1314368930404;
                        bS[8] = bS[9][bS[11]];
                        bS[5] = bS[7][bS[8]];
                        bS[7] = "Connect";
                        bS[7] = bS[5][bS[7]];
                        bS[8] = function(...)
                            v3 = r64;
                            if v3 ~= r159 then
                                v8 = r27;
                                v3 = v8.Create(v8, r160, TweenInfo.new(.3), {
                                    ["BackgroundTransparency"] = .1,
                                    ["Size"] = UDim2.new(1, -8, 0, 50)
                                });
                                v3.Play(v3);
                                v8 = r27;
                                v3 = v8.Create(v8, r161, TweenInfo.new(.3), {
                                    ["Rotation"] = 90
                                });
                                v3.Play(v3);
                                v8 = r27;
                                v3 = v8.Create(v8, r162, TweenInfo.new(.3), {
                                    ["ImageTransparency"] = .8
                                });
                                v3.Play(v3);
                                v8 = r27;
                                v3 = v8.Create(v8, o[bS[1]], TweenInfo.new(.3), {
                                    ["TextStrokeTransparency"] = .8
                                });
                                v3.Play(v3);
                            end;
                            return; 
                        end;
                        bS[7] = bS[7](bS[5], bS[8]);
                        bS[7] = r160;
                        bS[12] = "\xf0\"c?s;\x1e|\x18\x00\xdcT\xfa\x1c+\xa6)";
                        bS[9] = r15;
                        bS[1] = nil;
                        bS[10] = r16;
                        bS[11] = bS[10](bS[12], bS[13]);
                        bS[8] = bS[9][bS[11]];
                        bS[5] = bS[7][bS[8]];
                        bS[7] = "Connect";
                        bS[7] = bS[5][bS[7]];
                        bS[8] = function(...)
                            if not r47 then
                                return;
                            end;
                            if r38 then
                                o[bS[8]]();
                                return;
                            end;
                            o[bS[9]]();
                            task.delay(0.5, function(...)
                                r64 = r159;
                                r86();
                                r75();
                                q = r105;
                                P = {
                                    q.GetChildren(q)
                                };
                                N = q[3];
                                S = q[2];
                                for N, P in pairs(x(P)) do
                                    q = N;
                                    if P.IsA(P, "TextButton") then
                                        v2 = r15;
                                        if P.FindFirstChild(P, "SelectionIndicator") then
                                            v2 = P.Name == r64;
                                            v7 = v8;
                                            if v2 then
                                                c = UDim2.new(.03, 0, .6, 0);
                                            end;
                                            v8 = v8;
                                            v3 = v2;
                                            if v2 then
                                                v7 = c;
                                                c = v7;
                                                K = v2;
                                                if v2 then
                                                    K = Color3.fromRGB(180, 130, 230);
                                                end;
                                                v8 = v7;
                                                v3 = K;
                                                if K then
                                                    v8 = v7;
                                                    v3 = r27;
                                                    K = v3.Create(v3, v3, TweenInfo.new(.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                                                        ["BackgroundColor3"] = K,
                                                        ["Size"] = v7
                                                    });
                                                    K.Play(K);
                                                else
                                                    v3 = Color3.fromRGB(80, 50, 100);
                                                end;
                                            else
                                                v3 = UDim2.new(.02, 0, .4, 0);
                                            end;
                                        end;
                                    end; 
                                end;
                                task.delay(r46, function(...)
                                    v8 = r29.Character;
                                    if v8 then
                                        v8 = r29.Character;
                                        v1 = v8.FindFirstChild(v8, "Humanoid");
                                        if v1 then
                                            v3 = r38 and not r39;
                                            v8 = r29.Character;
                                        end;
                                        if v1 then
                                            o[bS[15]](v1, "Idle");
                                        end;
                                    end;
                                    return; 
                                end);
                                return; 
                            end);
                            return; 
                        end;
                        bS[6] = nil;
                        bS[7] = bS[7](bS[5], bS[8]);
                    else
                        bS[7] = "Color3";
                        bS[12] = 32561326766906;
                        bS[6] = Env[bS[7]];
                        bS[8] = r15;
                        bS[11] = "\xa0H\xb3;\xbe&\xaf";
                        bS[9] = r16;
                        bS[10] = bS[9](bS[11], bS[12]);
                        bS[9] = 100;
                        bS[7] = bS[8][bS[10]];
                        bS[5] = bS[6][bS[7]];
                        bS[8] = 50;
                        bS[7] = 80;
                        bS[6] = bS[5](bS[7], bS[8], bS[9]);
                        bS[3] = bS[6];
                    end; 
                end;
                HS = r148;
                bS[8] = 29586270156241;
                oS = HS.GetPropertyChangedSignal(HS, "AbsoluteContentSize");
                bS[1] = 11946997618107;
                oS.Connect(oS, function(...)
                    r105.CanvasSize = UDim2.new(0, 0, 0, r148.AbsoluteContentSize.Y + 10);
                    return; 
                end);
                local function r163(...)
                    if r149 then
                        r149.Text = "SPEED: " .. math.floor(r62) .. " (x" .. string.format("%.2f", r33) .. ")";
                    end;
                    v8 = r150;
                    if v8 then
                        v8 = r150;
                        q = v8;
                        v4 = q;
                        v8 = v4;
                        v8 = q;
                        v8.Text = "BOOST: " .. (r40 == 0 and "OFF" or "LEVEL " .. r40);
                    end;
                    if r151 then
                        v8 = r151;
                        v8 = v8;
                        v8 = v8;
                        v8.Text = "STATUS: " .. (r38 and "FLYING" or "GROUNDED");
                        v8 = r151;
                        P = r38;
                        if P then
                            N = Color3.fromRGB(120, 255, 120);
                        end;
                        v8 = v8;
                        if P then
                            v8 = v8;
                            v8.TextColor3 = P;
                            return;
                        else
                            v1 = Color3.fromRGB(255, 120, 120);
                        end;
                    end; 
                end;
                ZS = r24[r15[r16("\xd4\x1d\xbc\xed\xc3H\xc6\x86\xf1", bS[1])]];
                bS[1] = 2;
                oS = ZS.Connect(ZS, function(...)
                    if o[xS].Visible then
                        r163();
                    end;
                    return; 
                end);
                o[bS[23]](o[xS], L);
                o[bS[23]](r107, r107);
                local function SS(arg1_24, arg2_24, arg3_24, arg4_24, arg5_24, arg6_24, arg7_24, ...)
                    r164 = arg1_24;
                    r165 = arg2_24;
                    r166 = arg3_24;
                    r167 = arg4_24;
                    r168 = arg5_24;
                    r169 = arg7_24;
                    r170 = false;
                    local function r171(arg1_25, ...)
                        S = r164.AbsoluteSize.X;
                        P = math.clamp(arg1_25 - r164.AbsolutePosition.X, 0, S) / S;
                        v4 = r167 + (r168 - r167) * P;
                        v8 = r27;
                        v3 = v8.Create(v8, r165, TweenInfo.new(.1), {
                            ["Size"] = UDim2.new(P, 0, 1, 0)
                        });
                        v3.Play(v3);
                        r166.Text = string.format("%.1f", v4);
                        r169(v4);
                        return; 
                    end;
                    v8 = r164.InputBegan;
                    v8.Connect(v8, function(arg1_26, ...)
                        v1 = arg1_26;
                        if v1.UserInputType == Enum.UserInputType.MouseButton1 then
                            r170 = true;
                            r171(v1.Position.X);
                        end;
                        return; 
                    end);
                    v8 = r164.InputChanged;
                    v8.Connect(v8, function(arg1_27, ...)
                        v1 = arg1_27;
                        if v1.UserInputType == Enum.UserInputType.MouseMovement and r170 then
                            r171(v1.Position.X);
                        end;
                        return; 
                    end);
                    v8 = r164.InputEnded;
                    v8.Connect(v8, function(arg1_28, ...)
                        if arg1_28.UserInputType == Enum.UserInputType.MouseButton1 then
                            r170 = false;
                        end;
                        return; 
                    end);
                    r165.Size = UDim2.new((arg6_24 - r167) / (r168 - r167), 0, 1, 0);
                    return; 
                end;
                bS[9] = 10877818704841;
                bS[6] = "e\xe9J";
                bS[2] = r51;
                bS[3] = function(arg1_29, ...)
                    v8 = arg1_29;
                    r51 = v8;
                    r86();
                    v8 = v8;
                    if r38 and o[YL] then
                        o[bS[17]]();
                        S = r29.Character;
                        if S then
                            N = S.FindFirstChild(S, "HumanoidRootPart");
                            if N then
                                o[A[35]](N);
                            end;
                        end;
                    end;
                    return; 
                end;
                SS(kL, r153, r152, 0.5, bS[1], bS[2], bS[3]);
                bS[3] = function(arg1_30, ...)
                    v8 = arg1_30;
                    r52 = v8;
                    r86();
                    v8 = v8;
                    if r38 and o[YL] then
                        o[bS[17]]();
                        S = r29.Character;
                        if S then
                            N = S.FindFirstChild(S, "HumanoidRootPart");
                            if N then
                                o[A[35]](N);
                            end;
                        end;
                    end;
                    return; 
                end;
                bS[4] = 29983141639817;
                bS[1] = 5;
                bS[2] = r52;
                SS(YL, r155, r154, 1, bS[1], bS[2], bS[3]);
                bS[3] = "]e#\x84\x1b\xf5\x9f|X\xcd\x9cD\xc2\x14a\xa4\xb5";
                bS[1] = r16;
                bS[2] = bS[1](bS[3], bS[4]);
                bS[7] = 12541599192784;
                NS = r156[r15[bS[2]]];
                NS.Connect(NS, function(...)
                    v8 = r49;
                    r51 = v8;
                    r52 = r50;
                    N = r27;
                    q = N.Create(N, r153, TweenInfo.new(.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                        ["Size"] = UDim2.new((r51 - 0.5) / 1.5, 0, 1, 0)
                    });
                    q.Play(q);
                    N = r27;
                    q = N.Create(N, r155, TweenInfo.new(.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                        ["Size"] = UDim2.new((r52 - 1) / 4, 0, 1, 0)
                    });
                    q.Play(q);
                    task.wait(0.5);
                    r152.Text = string.format("%.1f", r51);
                    r154.Text = string.format("%.1f", r52);
                    P = r38;
                    if P then
                        N = o[YL];
                    end;
                    v8 = v8;
                    if P then
                        o[bS[17]]();
                        N = r29.Character;
                        if N then
                            q = N.FindFirstChild(N, "HumanoidRootPart");
                            if q then
                                o[A[35]](q);
                            end;
                        end;
                    end;
                    return; 
                end);
                bS[3] = "N\x96:4&\xe2\t\x8aJeSB\xc9~)\x1d\xdd";
                bS[4] = 15921533787382;
                bS[1] = r16;
                bS[2] = bS[1](bS[3], bS[4]);
                bS[3] = "\x1b\xcd\x1f";
                NS = r146[r15[bS[2]]];
                bS[20] = 7717853187593;
                NS.Connect(NS, function(...)
                    r104 = not r104;
                    if r104 then
                        o[xS].Visible = true;
                        v3 = r27;
                        v1 = v3.Create(v3, o[xS], TweenInfo.new(.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                            ["Position"] = UDim2.new(1, -70, 0.5, 0)
                        });
                        v1.Play(v1);
                        v3 = r27;
                        v1 = v3.Create(v3, r107, TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                            ["ImageColor3"] = Color3.fromRGB(200, 150, 255)
                        });
                        v1.Play(v1);
                        r163();
                    else
                        v3 = r27;
                        v1 = v3.Create(v3, o[xS], TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                            ["Position"] = UDim2.new(1, 400, 0.5, 0)
                        });
                        v1.Play(v1);
                        v3 = r27;
                        v1 = v3.Create(v3, r107, TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                            ["ImageColor3"] = Color3.fromRGB(240, 200, 255)
                        });
                        v1.Play(v1);
                        task.wait(0.5);
                        if not r104 then
                            o[xS].Visible = false;
                        end;
                        return;
                    end; 
                end);
                bS[4] = 1857679213409;
                bS[1] = r16;
                bS[2] = bS[1](bS[3], bS[4]);
                bS[3] = "\x97\xe4\x08\xe1k\xca\x17*L\xfdSY";
                bS[4] = 34796188188491;
                bS[1] = r16;
                bS[2] = bS[1](bS[3], bS[4]);
                bS[4] = 16845761912484;
                bS[14] = 2656209437908;
                r172 = Instance[r15[bS[2]]](r15[bS[2]]);
                bS[3] = "\x14\xff\xa2e)@2";
                bS[1] = r16;
                bS[2] = bS[1](bS[3], bS[4]);
                bS[2] = "UDim";
                bS[1] = Env[bS[2]];
                bS[3] = r15;
                bS[4] = r16;
                bS[5] = bS[4](bS[6], bS[7]);
                bS[4] = 6426019974064;
                bS[2] = bS[3][bS[5]];
                bS[2] = 0;
                bS[3] = 10;
                bS[1] = bS[1][bS[2]](bS[2], bS[3]);
                r172[r15[bS[2]]] = bS[1];
                bS[3] = "\xdeQ\x06|*>\xfb\x83\xdc";
                bS[1] = r16;
                bS[2] = bS[1](bS[3], bS[4]);
                bS[7] = "\x91\xbf8\xb3\xe4\x1f\xd0\xfeU";
                bS[16] = 25103562141097;
                bS[3] = "Enum";
                bS[2] = Env[bS[3]];
                bS[4] = r15;
                bS[5] = r16;
                bS[6] = bS[5](bS[7], bS[8]);
                bS[3] = bS[4][bS[6]];
                bS[1] = bS[2][bS[3]];
                bS[7] = 7340368727386;
                bS[3] = r15;
                bS[4] = r16;
                bS[6] = "\x95\xc5\x84\xf8<\xc9\xa9\xf1\x9dY\xfc";
                bS[5] = bS[4](bS[6], bS[7]);
                bS[11] = 27158681481574;
                bS[2] = bS[3][bS[5]];
                bS[5] = 31493134514505;
                bS[3] = "-L\xbb\xdb\xceq";
                bS[4] = 19542088819595;
                r172[r15[bS[2]]] = bS[1][bS[2]];
                bS[1] = r16;
                bS[2] = bS[1](bS[3], bS[4]);
                bS[4] = "-\xa1\x02";
                r172[r15[bS[2]]] = r144;
                bS[1] = r15;
                bS[2] = r16;
                bS[3] = bS[2](bS[4], bS[5]);
                bS[5] = 28723343438911;
                bS[4] = "\x9d\xc8\xc4\x9d8";
                bS[1] = r15;
                bS[17] = 1253495030343;
                bS[2] = r16;
                bS[3] = bS[2](bS[4], bS[5]);
                bS[4] = "\xff\x8d\xa1l";
                bS[5] = 29627712468452;
                bS[7] = "ZK\xce";
                r173 = Instance[bS[1][bS[3]]](bS[1][bS[3]]);
                bS[6] = 3065706726803;
                bS[1] = r15;
                bS[2] = r16;
                bS[3] = bS[2](bS[4], bS[5]);
                bS[2] = r15;
                bS[5] = "\x17\xc0\xfa\xb5\xf5\xbc\xe5\x8f\xd6\x16\xb1\x04\r\x94\xad";
                bS[3] = r16;
                bS[4] = bS[3](bS[5], bS[6]);
                bS[1] = bS[2][bS[4]];
                bS[4] = "'\x04R\xdb";
                bS[8] = 19338242925357;
                r173[bS[1][bS[3]]] = bS[1];
                bS[5] = 4987297073426;
                bS[1] = r15;
                bS[2] = r16;
                bS[3] = bS[2](bS[4], bS[5]);
                bS[3] = "UDim2";
                bS[2] = Env[bS[3]];
                bS[4] = r15;
                bS[5] = r16;
                bS[6] = bS[5](bS[7], bS[8]);
                bS[18] = 33786530610549;
                bS[3] = bS[4][bS[6]];
                bS[5] = 0;
                bS[4] = 0;
                bS[1] = bS[2][bS[3]];
                bS[6] = 300;
                bS[3] = 1;
                bS[2] = bS[1](bS[3], bS[4], bS[5], bS[6]);
                r173[bS[1][bS[3]]] = bS[2];
                bS[6] = 2617469289666;
                bS[1] = r15;
                bS[2] = r16;
                bS[5] = 25744623120084;
                bS[4] = "\x0ez\xa9\x10\xf3+V\xd7?\xd0\xc8i\xdd\xbazW\xc4\xe0\x8f\xe9\x9f\x90";
                bS[3] = bS[2](bS[4], bS[5]);
                bS[4] = "\x82\xf5\xea\xf3\x1c]<\xdf\x81 \x83";
                bS[1] = 1;
                r173[bS[1][bS[3]]] = bS[1];
                bS[5] = 18302203781450;
                bS[1] = r15;
                bS[12] = 10675293623147;
                bS[2] = r16;
                bS[3] = bS[2](bS[4], bS[5]);
                bS[1] = 1;
                r173[bS[1][bS[3]]] = bS[1];
                bS[5] = 24264116235298;
                bS[8] = 1286114378326;
                bS[4] = "\x84y6\xac\x0e\xab";
                bS[1] = r15;
                bS[2] = r16;
                bS[3] = bS[2](bS[4], bS[5]);
                bS[1] = r144;
                r173[bS[1][bS[3]]] = bS[1];
                bS[1] = "Instance";
                bS[2] = r15;
                bS[5] = "\xf3@g";
                bS[3] = r16;
                bS[4] = bS[3](bS[5], bS[6]);
                bS[1] = bS[2][bS[4]];
                bS[6] = 11584841979154;
                bS[7] = "q@\xa9";
                bS[2] = r15;
                bS[5] = "\xb7\xcc\xb9\x8b\x99\x06\xac\x0e\x02";
                bS[3] = r16;
                bS[4] = bS[3](bS[5], bS[6]);
                bS[6] = 11576870130958;
                bS[1] = bS[2][bS[4]];
                PS = Env[bS[1]][bS[1]](bS[1]);
                bS[1] = r15;
                bS[2] = r16;
                bS[5] = 19257746498311;
                bS[4] = "\xf8\xf4\x057";
                bS[3] = bS[2](bS[4], bS[5]);
                bS[5] = "\xd9\xb8r\xc6\x13";
                bS[2] = r15;
                bS[3] = r16;
                bS[4] = bS[3](bS[5], bS[6]);
                bS[1] = bS[2][bS[4]];
                PS[bS[1][bS[3]]] = bS[1];
                bS[5] = 6549576289257;
                bS[1] = r15;
                bS[2] = r16;
                bS[4] = "`\"\x84\xf5";
                bS[3] = bS[2](bS[4], bS[5]);
                bS[3] = "UDim2";
                bS[2] = Env[bS[3]];
                bS[4] = r15;
                bS[5] = r16;
                bS[6] = bS[5](bS[7], bS[8]);
                bS[3] = bS[4][bS[6]];
                bS[1] = bS[2][bS[3]];
                bS[5] = 0;
                bS[4] = 0;
                bS[3] = 1;
                bS[6] = 30;
                bS[2] = bS[1](bS[3], bS[4], bS[5], bS[6]);
                PS[bS[1][bS[3]]] = bS[2];
                bS[5] = 13121356355550;
                bS[1] = r15;
                bS[2] = r16;
                bS[4] = "jS\xd0:\x18\xb5|\xd9";
                bS[3] = bS[2](bS[4], bS[5]);
                bS[8] = 14388179049004;
                bS[3] = "UDim2";
                bS[2] = Env[bS[3]];
                bS[4] = r15;
                bS[7] = "\xb3\xb02";
                bS[5] = r16;
                bS[6] = bS[5](bS[7], bS[8]);
                bS[5] = 0;
                bS[8] = 11266002621566;
                bS[3] = bS[4][bS[6]];
                bS[1] = bS[2][bS[3]];
                bS[6] = 0;
                bS[3] = 0;
                bS[4] = 0;
                bS[2] = bS[1](bS[3], bS[4], bS[5], bS[6]);
                bS[5] = 28151551161141;
                PS[bS[1][bS[3]]] = bS[2];
                bS[1] = r15;
                bS[4] = "\x96\xc5=\x9e\x0c_\xac]\xdf\xc8*\xc4\xe2u\xc2\\\x1c\x82\xfd\xe3X\xec";
                bS[2] = r16;
                bS[3] = bS[2](bS[4], bS[5]);
                bS[1] = 1;
                bS[4] = ".7\x00\xe4";
                PS[bS[1][bS[3]]] = bS[1];
                bS[5] = 6006219246316;
                bS[1] = r15;
                bS[6] = 7833410932287;
                bS[2] = r16;
                bS[3] = bS[2](bS[4], bS[5]);
                bS[2] = r15;
                bS[3] = r16;
                bS[5] = "V\xb6L]X\x15c5";
                bS[4] = bS[3](bS[5], bS[6]);
                bS[1] = bS[2][bS[4]];
                bS[5] = 340040450206;
                PS[bS[1][bS[3]]] = bS[1];
                bS[7] = "\x1b\xe5\x9d=\xe7\xc3\x91";
                bS[1] = r15;
                bS[2] = r16;
                bS[4] = "8\xcd\xf8(\x128\xdc\xdd*\xcf";
                bS[3] = bS[2](bS[4], bS[5]);
                bS[3] = "Color3";
                bS[2] = Env[bS[3]];
                bS[4] = r15;
                bS[5] = r16;
                bS[6] = bS[5](bS[7], bS[8]);
                bS[3] = bS[4][bS[6]];
                bS[1] = bS[2][bS[3]];
                bS[5] = 255;
                bS[4] = 200;
                bS[3] = 230;
                bS[2] = bS[1](bS[3], bS[4], bS[5]);
                PS[bS[1][bS[3]]] = bS[2];
                bS[1] = r15;
                bS[5] = 23754944719669;
                bS[2] = r16;
                bS[4] = "\xb9l\xb6[\xa7nW\xd7";
                bS[3] = bS[2](bS[4], bS[5]);
                bS[1] = 16;
                bS[5] = 2197719663615;
                PS[bS[1][bS[3]]] = bS[1];
                bS[1] = r15;
                bS[4] = "4)'\xe9";
                bS[2] = r16;
                bS[3] = bS[2](bS[4], bS[5]);
                bS[8] = "\x15\xe5\x10#";
                bS[13] = 7398851382645;
                bS[4] = "Enum";
                bS[3] = Env[bS[4]];
                bS[5] = r15;
                bS[6] = r16;
                bS[7] = bS[6](bS[8], bS[9]);
                bS[4] = bS[5][bS[7]];
                bS[8] = 5416334526938;
                bS[7] = "\xc9\xcf\xf2\xcb\xc4$?[\xbd\xf6";
                bS[2] = bS[3][bS[4]];
                bS[4] = r15;
                bS[5] = r16;
                bS[6] = bS[5](bS[7], bS[8]);
                bS[5] = 14739318872783;
                bS[3] = bS[4][bS[6]];
                bS[4] = "\x1e\xef\xb1*\xa6\x16";
                bS[1] = bS[2][bS[3]];
                PS[bS[1][bS[3]]] = bS[1];
                bS[1] = r15;
                bS[9] = 15844841381074;
                bS[10] = 11411644552385;
                bS[2] = r16;
                bS[3] = bS[2](bS[4], bS[5]);
                bS[1] = r173;
                PS[bS[1][bS[3]]] = bS[1];
                bS[1] = 40;
                bS[5] = r15;
                bS[6] = r16;
                bS[8] = "\xe5\xf7\x1c";
                bS[7] = bS[6](bS[8], bS[9]);
                bS[9] = "{\xdd\xb7-\x87\xd3#\xf2\xfa(\x8f:";
                bS[4] = bS[5][bS[7]];
                bS[6] = r15;
                bS[7] = r16;
                bS[8] = bS[7](bS[9], bS[10]);
                bS[5] = bS[6][bS[8]];
                bS[7] = r15;
                bS[8] = r16;
                bS[10] = "\x98\xec\x80A\xbe9\xb6";
                bS[9] = bS[8](bS[10], bS[11]);
                bS[11] = "\x1c{\xbd\xf0\xe9\xea\x1f2\xca\x1evN\xae";
                bS[6] = bS[7][bS[9]];
                bS[8] = r15;
                bS[9] = r16;
                bS[10] = bS[9](bS[11], bS[12]);
                bS[12] = 14401169742386;
                bS[7] = bS[8][bS[10]];
                bS[3] = {
                    [bS[4]] = bS[5],
                    [bS[6]] = bS[7]
                };
                bS[9] = " \xb4\x14";
                bS[6] = r15;
                bS[10] = 17810452406373;
                bS[7] = r16;
                bS[8] = bS[7](bS[9], bS[10]);
                bS[5] = bS[6][bS[8]];
                bS[11] = 16208752926075;
                bS[7] = r15;
                bS[8] = r16;
                bS[10] = "a\xdb;ms\xb1\xb7\x08Hh";
                bS[9] = bS[8](bS[10], bS[11]);
                bS[6] = bS[7][bS[9]];
                bS[8] = r15;
                bS[9] = r16;
                bS[11] = "3-k\xfa\x0e\xd8\xa9";
                bS[10] = bS[9](bS[11], bS[12]);
                bS[7] = bS[8][bS[10]];
                bS[9] = r15;
                bS[12] = "!\xf3\xad'\xe7\x81\x975\xeb\xbdQ";
                bS[10] = r16;
                bS[11] = bS[10](bS[12], bS[13]);
                bS[8] = bS[9][bS[11]];
                bS[13] = 17558933233648;
                bS[12] = 15593042353245;
                bS[11] = 4415322671112;
                bS[4] = {
                    [bS[5]] = bS[6],
                    [bS[7]] = bS[8]
                };
                bS[7] = r15;
                bS[8] = r16;
                bS[10] = "IHa";
                bS[9] = bS[8](bS[10], bS[11]);
                bS[11] = "\xb5\x17\xed\x8b4\xa7";
                bS[6] = bS[7][bS[9]];
                bS[8] = r15;
                bS[9] = r16;
                bS[10] = bS[9](bS[11], bS[12]);
                bS[7] = bS[8][bS[10]];
                bS[9] = r15;
                bS[10] = r16;
                bS[12] = "\xd2\x14\x94\xc57vI";
                bS[11] = bS[10](bS[12], bS[13]);
                bS[19] = 30833678907414;
                bS[8] = bS[9][bS[11]];
                bS[10] = r15;
                bS[11] = r16;
                bS[13] = "\x15\x060l\xaf\x17\xa3";
                bS[15] = 26442013175833;
                bS[12] = bS[11](bS[13], bS[14]);
                bS[9] = bS[10][bS[12]];
                bS[5] = {
                    [bS[6]] = bS[7],
                    [bS[8]] = bS[9]
                };
                bS[12] = 19667245966278;
                bS[11] = "=P\xb1";
                bS[8] = r15;
                bS[9] = r16;
                bS[10] = bS[9](bS[11], bS[12]);
                bS[7] = bS[8][bS[10]];
                bS[9] = r15;
                bS[14] = 28235251888988;
                bS[12] = "\xf5\x02x\x03ZF\x95\xce\xa9w";
                bS[13] = 27845644726950;
                bS[10] = r16;
                bS[11] = bS[10](bS[12], bS[13]);
                bS[13] = "\xd2b\x9fg\xbc\x9d\x1e";
                bS[8] = bS[9][bS[11]];
                bS[10] = r15;
                bS[11] = r16;
                bS[12] = bS[11](bS[13], bS[14]);
                bS[14] = "\xad!\xfe*[)\xdb\x11\xcfr\xb3";
                bS[9] = bS[10][bS[12]];
                bS[11] = r15;
                bS[12] = r16;
                bS[13] = bS[12](bS[14], bS[15]);
                bS[10] = bS[11][bS[13]];
                bS[12] = "\xad\xd5\x08";
                bS[6] = {
                    [bS[7]] = bS[8],
                    [bS[9]] = bS[10]
                };
                bS[9] = r15;
                bS[10] = r16;
                bS[13] = 25154301390273;
                bS[15] = 32044338969161;
                bS[11] = bS[10](bS[12], bS[13]);
                bS[8] = bS[9][bS[11]];
                bS[14] = 12445261239971;
                bS[10] = r15;
                bS[13] = "\xce\xaa-\xe0\x83\x0c\xba\x83\x9b\xbe\x9b";
                bS[11] = r16;
                bS[12] = bS[11](bS[13], bS[14]);
                bS[14] = "\x8d{~\xb6Q\x0c\x82";
                bS[9] = bS[10][bS[12]];
                bS[11] = r15;
                bS[12] = r16;
                bS[13] = bS[12](bS[14], bS[15]);
                bS[10] = bS[11][bS[13]];
                bS[12] = r15;
                bS[15] = "m=\xc8\xe1\x87\xc0l|\x03\xf4n\x10";
                bS[13] = r16;
                bS[14] = bS[13](bS[15], bS[16]);
                bS[13] = "\xaa\xef\x9e";
                bS[11] = bS[12][bS[14]];
                bS[7] = {
                    [bS[8]] = bS[9],
                    [bS[10]] = bS[11]
                };
                bS[10] = r15;
                bS[14] = 21759877457812;
                bS[15] = 482552987872;
                bS[11] = r16;
                bS[12] = bS[11](bS[13], bS[14]);
                bS[9] = bS[10][bS[12]];
                bS[16] = 13115010930651;
                bS[11] = r15;
                bS[14] = "\x9d\xb5\xca\xba\x1dJ\xa0";
                bS[12] = r16;
                bS[13] = bS[12](bS[14], bS[15]);
                bS[15] = "\x93W\xf1tv\xad:";
                bS[10] = bS[11][bS[13]];
                bS[12] = r15;
                bS[13] = r16;
                bS[14] = bS[13](bS[15], bS[16]);
                bS[11] = bS[12][bS[14]];
                bS[13] = r15;
                bS[14] = r16;
                bS[16] = "{\xe6\x83o\xb1\xb5\xf1j";
                bS[15] = bS[14](bS[16], bS[17]);
                bS[12] = bS[13][bS[15]];
                bS[14] = "\x7f\x13\xcd";
                bS[8] = {
                    [bS[9]] = bS[10],
                    [bS[11]] = bS[12]
                };
                bS[11] = r15;
                bS[12] = r16;
                bS[15] = 27062724260154;
                bS[13] = bS[12](bS[14], bS[15]);
                bS[10] = bS[11][bS[13]];
                bS[15] = "1\x93\xff4\xa8\xfc\x06\xf9";
                bS[12] = r15;
                bS[13] = r16;
                bS[16] = 28096807564059;
                bS[14] = bS[13](bS[15], bS[16]);
                bS[16] = "0<\x9c\x94\xd0\xc1\x02";
                bS[11] = bS[12][bS[14]];
                bS[13] = r15;
                bS[14] = r16;
                bS[17] = 25817740979958;
                bS[15] = bS[14](bS[16], bS[17]);
                bS[17] = "\xde\x08ZV\xbe.C$\xb1";
                bS[12] = bS[13][bS[15]];
                bS[14] = r15;
                bS[15] = r16;
                bS[16] = bS[15](bS[17], bS[18]);
                bS[13] = bS[14][bS[16]];
                bS[9] = {
                    [bS[10]] = bS[11],
                    [bS[12]] = bS[13]
                };
                bS[12] = r15;
                bS[15] = "\x1b\x8a\x99";
                bS[18] = 24601264221375;
                bS[16] = 14988837526339;
                bS[13] = r16;
                bS[14] = bS[13](bS[15], bS[16]);
                bS[16] = "\xceh\xef\x161\xc0";
                bS[11] = bS[12][bS[14]];
                bS[13] = r15;
                bS[14] = r16;
                bS[17] = 13680128317666;
                bS[15] = bS[14](bS[16], bS[17]);
                bS[12] = bS[13][bS[15]];
                bS[14] = r15;
                bS[15] = r16;
                bS[17] = "\xa2V\xeb\xc22\xaa5";
                bS[16] = bS[15](bS[17], bS[18]);
                bS[13] = bS[14][bS[16]];
                bS[15] = r15;
                bS[16] = r16;
                bS[18] = "\x9c\x18\xb72b\xfb";
                bS[17] = bS[16](bS[18], bS[19]);
                bS[14] = bS[15][bS[17]];
                bS[10] = {
                    [bS[11]] = bS[12],
                    [bS[13]] = bS[14]
                };
                bS[13] = r15;
                bS[14] = r16;
                bS[16] = "^\x00\x9a";
                bS[17] = 25091772870052;
                bS[18] = 16575573614118;
                bS[15] = bS[14](bS[16], bS[17]);
                bS[12] = bS[13][bS[15]];
                bS[14] = r15;
                bS[15] = r16;
                bS[19] = 6324600441729;
                bS[17] = "H#\x9d2\xeb\xf9\x19";
                bS[16] = bS[15](bS[17], bS[18]);
                bS[13] = bS[14][bS[16]];
                bS[15] = r15;
                bS[18] = "\\\x05-\xa6{\x7f\xf2";
                bS[16] = r16;
                bS[17] = bS[16](bS[18], bS[19]);
                bS[14] = bS[15][bS[17]];
                bS[16] = r15;
                bS[17] = r16;
                bS[19] = "\xa8\xc4\xafdF\x04\xd3";
                bS[18] = bS[17](bS[19], bS[20]);
                bS[15] = bS[16][bS[18]];
                bS[11] = {
                    [bS[12]] = bS[13],
                    [bS[14]] = bS[15]
                };
                bS[2] = {
                    bS[3],
                    bS[4],
                    bS[5],
                    bS[6],
                    bS[7],
                    bS[8],
                    bS[9],
                    bS[10],
                    bS[11]
                };
                bS[3] = 154;
                bS[4] = "ipairs";
                o[bS[3]] = bS[2];
                bS[2] = Env[bS[4]];
                bS[7] = o[bS[3]];
                bS[8] = {
                    bS[2](bS[7])
                };
                bS[5] = bS[8][2];
                bS[6] = bS[8][3];
                bS[4] = bS[8][1];
                bS[6], bS[7] = bS[4](bS[5], bS[6]);
                while bS[6] do
                    bS[18] = 15116704570239;
                    bS[11] = r15;
                    bS[2] = bS[6];
                    bS[14] = "\xdd\xd5\x83";
                    bS[17] = "\xf3\xe8&";
                    bS[12] = r16;
                    bS[15] = 32784326540194;
                    bS[13] = bS[12](bS[14], bS[15]);
                    bS[10] = bS[11][bS[13]];
                    bS[9] = bS[7][bS[10]];
                    bS[12] = r15;
                    bS[16] = 20725770184115;
                    bS[15] = "`\x80`>\xd2,\xd6";
                    bS[13] = r16;
                    bS[14] = bS[13](bS[15], bS[16]);
                    bS[11] = bS[12][bS[14]];
                    bS[10] = bS[7][bS[11]];
                    bS[13] = "UDim2";
                    bS[12] = Env[bS[13]];
                    bS[7] = nil;
                    bS[14] = r15;
                    bS[15] = r16;
                    bS[16] = bS[15](bS[17], bS[18]);
                    bS[13] = bS[14][bS[16]];
                    bS[15] = 0;
                    bS[14] = 0;
                    bS[18] = 1;
                    bS[11] = bS[12][bS[13]];
                    bS[13] = 0;
                    bS[17] = bS[2] - bS[18];
                    bS[2] = nil;
                    bS[16] = bS[1] * bS[17];
                    bS[12] = bS[11](bS[13], bS[14], bS[15], bS[16]);
                    bS[11] = r173;
                    bS[8] = (function(arg1_31, arg2_31, arg3_31, arg4_31, ...)
                        r174 = arg1_31;
                        P = Instance.new("Frame");
                        P.Name = r174 .. "Container";
                        P.Size = UDim2.new(1, 0, 0, 40);
                        v3 = arg3_31;
                        P.Position = v3;
                        P.BackgroundTransparency = 1;
                        v3 = arg4_31;
                        P.Parent = v3;
                        v4 = Instance.new("TextLabel");
                        v4.Name = "Label";
                        v4.Size = UDim2.new(.6, 0, 1, 0);
                        v4.Position = UDim2.new(0, 0, 0, 0);
                        v4.BackgroundTransparency = 1;
                        v3 = arg2_31;
                        v4.Text = v3;
                        v4.TextColor3 = Color3.fromRGB(210, 180, 240);
                        v4.TextSize = 14;
                        v4.TextXAlignment = Enum.TextXAlignment.Left;
                        v4.Font = Enum.Font.GothamMedium;
                        v4.Parent = P;
                        r175 = Instance.new("TextButton");
                        r175.Name = "KeybindButton";
                        r175.Size = UDim2.new(.35, 0, .7, 0);
                        r175.Position = UDim2.new(.6, 0, .15, 0);
                        r175.BackgroundColor3 = Color3.fromRGB(50, 30, 70);
                        r175.BackgroundTransparency = .1;
                        c = tostring(r43[r174]);
                        r175.Text = c.gsub(c, "Enum.KeyCode.", "");
                        r175.TextColor3 = Color3.fromRGB(255, 255, 255);
                        r175.TextSize = 12;
                        r175.Font = Enum.Font.GothamMedium;
                        r175.Parent = P;
                        v7 = Instance.new("UICorner");
                        v7.CornerRadius = UDim.new(0, 5);
                        v7.Parent = r175;
                        r176 = false;
                        v8 = r175.MouseButton1Click;
                        v8.Connect(v8, function(...)
                            if r176 then
                                return;
                            end;
                            r176 = true;
                            r175.Text = "[Press any key]";
                            r175.BackgroundColor3 = Color3.fromRGB(180, 130, 230);
                            v3 = r25.InputBegan;
                            r177 = v3.Connect(v3, function(arg1_32, ...)
                                v1 = arg1_32;
                                S = Enum.UserInputType.Keyboard;
                                if v1.UserInputType == S then
                                    r43[r174] = v1.KeyCode;
                                    N = tostring(v1.KeyCode);
                                    r175.Text = N.gsub(N, "Enum.KeyCode.", "");
                                    r176 = false;
                                    v3 = r177;
                                    v3.Disconnect(v3);
                                    r86();
                                    v3 = r27;
                                    S = v3.Create(v3, r175, TweenInfo.new(.3), {
                                        ["BackgroundColor3"] = Color3.fromRGB(50, 30, 70)
                                    });
                                    S.Play(S);
                                end;
                                return; 
                            end);
                            task.delay(5, function(...)
                                if r176 then
                                    r176 = false;
                                    N = tostring(r43[r174]);
                                    r175.Text = N.gsub(N, "Enum.KeyCode.", "");
                                    v3 = o[v1];
                                    v3.Disconnect(v3);
                                    v3 = r27;
                                    v1 = v3.Create(v3, r175, TweenInfo.new(.3), {
                                        ["BackgroundColor3"] = Color3.fromRGB(50, 30, 70)
                                    });
                                    v1.Play(v1);
                                end;
                                return; 
                            end);
                            return; 
                        end);
                        return r175; 
                    end)(bS[9], bS[10], bS[12], bS[11]); 
                end;
                bS[5] = "Instance";
                bS[4] = Env[bS[5]];
                bS[10] = 2015277122474;
                bS[6] = r15;
                bS[9] = "2\\\xa7";
                bS[7] = r16;
                bS[8] = bS[7](bS[9], bS[10]);
                bS[12] = 25336910425622;
                bS[5] = bS[6][bS[8]];
                bS[2] = bS[4][bS[5]];
                bS[6] = r15;
                bS[10] = 1134440432144;
                bS[7] = r16;
                bS[9] = "\xcfXO\x10\xc8";
                bS[8] = bS[7](bS[9], bS[10]);
                bS[5] = bS[6][bS[8]];
                bS[4] = bS[2](bS[5]);
                bS[8] = "\xb6\xb0W\x8d";
                bS[9] = 32675637803887;
                bS[5] = r15;
                bS[6] = r16;
                bS[7] = bS[6](bS[8], bS[9]);
                bS[9] = "f k\xc5\xb5\xe4\xd6\xe79\xf4\x8a";
                bS[2] = bS[5][bS[7]];
                bS[6] = r15;
                bS[7] = r16;
                bS[10] = 4671486560383;
                bS[8] = bS[7](bS[9], bS[10]);
                bS[5] = bS[6][bS[8]];
                bS[9] = 20801686398422;
                bS[4][bS[2]] = bS[5];
                bS[5] = r15;
                bS[8] = "\xdb\x9f\xa3\xd3";
                bS[6] = r16;
                bS[7] = bS[6](bS[8], bS[9]);
                bS[2] = bS[5][bS[7]];
                bS[7] = "UDim2";
                bS[6] = Env[bS[7]];
                bS[8] = r15;
                bS[9] = r16;
                bS[11] = "?&m";
                bS[10] = bS[9](bS[11], bS[12]);
                bS[7] = bS[8][bS[10]];
                bS[9] = 0;
                bS[10] = 40;
                bS[8] = 0;
                bS[5] = bS[6][bS[7]];
                bS[7] = 1;
                bS[6] = bS[5](bS[7], bS[8], bS[9], bS[10]);
                bS[4][bS[2]] = bS[6];
                bS[5] = r15;
                bS[9] = 32906738449371;
                bS[8] = "y\xb9Ec\xa3\xcb\xc7,E\xb4\xddq\x1c\x1b\xdcu\x8e8j\xde\xb68";
                bS[13] = 18341040693596;
                bS[6] = r16;
                bS[7] = bS[6](bS[8], bS[9]);
                bS[2] = bS[5][bS[7]];
                bS[5] = 1;
                bS[4][bS[2]] = bS[5];
                bS[9] = 12059327469039;
                bS[5] = r15;
                bS[8] = "\xe6\xb3\xdb\xdao%\xa0n\xfa\x82)";
                bS[6] = r16;
                bS[7] = bS[6](bS[8], bS[9]);
                bS[2] = bS[5][bS[7]];
                bS[11] = 10167627600510;
                bS[5] = 2;
                bS[4][bS[2]] = bS[5];
                bS[5] = r15;
                bS[6] = r16;
                bS[9] = 15306839710679;
                bS[10] = "\xfd\x12\xf9";
                bS[8] = "\xb5\x11\xd9[\xcbh";
                bS[7] = bS[6](bS[8], bS[9]);
                bS[2] = bS[5][bS[7]];
                bS[5] = r144;
                bS[4][bS[2]] = bS[5];
                bS[12] = "<5\x16";
                bS[6] = "Instance";
                bS[5] = Env[bS[6]];
                bS[7] = r15;
                bS[8] = r16;
                bS[9] = bS[8](bS[10], bS[11]);
                bS[11] = 8919294349369;
                bS[6] = bS[7][bS[9]];
                bS[2] = bS[5][bS[6]];
                bS[7] = r15;
                bS[8] = r16;
                bS[10] = "\x8a\x05\xa3N\xb7";
                bS[9] = bS[8](bS[10], bS[11]);
                bS[6] = bS[7][bS[9]];
                bS[5] = bS[2](bS[6]);
                bS[10] = 5226029762945;
                bS[6] = r15;
                bS[7] = r16;
                bS[9] = "\t7\xc72";
                bS[8] = bS[7](bS[9], bS[10]);
                bS[10] = "J\x84.\x8a\xda\xef\xfc&o\x1b\xefs\xf3";
                bS[2] = bS[6][bS[8]];
                bS[11] = 31927505058323;
                bS[7] = r15;
                bS[8] = r16;
                bS[9] = bS[8](bS[10], bS[11]);
                bS[6] = bS[7][bS[9]];
                bS[9] = "#\xe5s\xe2";
                bS[10] = 9401847337242;
                bS[5][bS[2]] = bS[6];
                bS[6] = r15;
                bS[7] = r16;
                bS[8] = bS[7](bS[9], bS[10]);
                bS[2] = bS[6][bS[8]];
                bS[8] = "UDim2";
                bS[7] = Env[bS[8]];
                bS[9] = r15;
                bS[10] = r16;
                bS[11] = bS[10](bS[12], bS[13]);
                bS[10] = 0;
                bS[8] = bS[9][bS[11]];
                bS[6] = bS[7][bS[8]];
                bS[8] = 1;
                bS[11] = 50;
                bS[9] = 0;
                bS[7] = bS[6](bS[8], bS[9], bS[10], bS[11]);
                bS[9] = "62*\xa4\xa5\xa4+F\x11\xf3q\x97\xc4\xabk\xda\x96\xea\xe5\xfc\xdf\xc2";
                bS[12] = 23814368963409;
                bS[10] = 33181000088667;
                bS[5][bS[2]] = bS[7];
                bS[6] = r15;
                bS[7] = r16;
                bS[8] = bS[7](bS[9], bS[10]);
                bS[2] = bS[6][bS[8]];
                bS[6] = 1;
                bS[10] = 1280199492180;
                bS[5][bS[2]] = bS[6];
                bS[6] = r15;
                bS[7] = r16;
                bS[9] = "I\xc7q\xf1E5#dO\t\x9b";
                bS[8] = bS[7](bS[9], bS[10]);
                bS[9] = "\x8a\x98\x86\xa3NB";
                bS[2] = bS[6][bS[8]];
                bS[6] = 2.5;
                bS[5][bS[2]] = bS[6];
                bS[10] = 11253476168824;
                bS[6] = r15;
                bS[7] = r16;
                bS[8] = bS[7](bS[9], bS[10]);
                bS[2] = bS[6][bS[8]];
                bS[6] = r144;
                bS[7] = "Instance";
                bS[5][bS[2]] = bS[6];
                bS[6] = Env[bS[7]];
                bS[11] = "\xffl\xdc";
                bS[8] = r15;
                bS[9] = r16;
                bS[10] = bS[9](bS[11], bS[12]);
                bS[7] = bS[8][bS[10]];
                bS[2] = bS[6][bS[7]];
                bS[8] = r15;
                bS[11] = "\xd4n!_\xfea\xaa~e";
                bS[12] = 35066730102729;
                bS[9] = r16;
                bS[10] = bS[9](bS[11], bS[12]);
                bS[15] = 12543349413584;
                bS[14] = 21891620513746;
                bS[7] = bS[8][bS[10]];
                bS[6] = bS[2](bS[7]);
                bS[11] = 26242313695164;
                bS[12] = 2310125192243;
                bS[10] = "\xfdQ\x12\xdf";
                bS[7] = r15;
                bS[8] = r16;
                bS[9] = bS[8](bS[10], bS[11]);
                bS[11] = "\n1\xbd\x86c";
                bS[2] = bS[7][bS[9]];
                bS[13] = "Q 9";
                bS[8] = r15;
                bS[9] = r16;
                bS[10] = bS[9](bS[11], bS[12]);
                bS[7] = bS[8][bS[10]];
                bS[11] = 24483622235273;
                bS[6][bS[2]] = bS[7];
                bS[10] = ".\xa3\x15\xb6";
                bS[7] = r15;
                bS[8] = r16;
                bS[9] = bS[8](bS[10], bS[11]);
                bS[2] = bS[7][bS[9]];
                bS[9] = "UDim2";
                bS[8] = Env[bS[9]];
                bS[10] = r15;
                bS[11] = r16;
                bS[12] = bS[11](bS[13], bS[14]);
                bS[9] = bS[10][bS[12]];
                bS[7] = bS[8][bS[9]];
                bS[11] = 1;
                bS[14] = 5874823744175;
                bS[10] = 0;
                bS[12] = 0;
                bS[9] = .7;
                bS[13] = "\x07@\xe8";
                bS[8] = bS[7](bS[9], bS[10], bS[11], bS[12]);
                bS[6][bS[2]] = bS[8];
                bS[7] = r15;
                bS[11] = 27401898062296;
                bS[10] = "\xc2\xb8\xbe\x8e\xd3{\n\xfb";
                bS[8] = r16;
                bS[9] = bS[8](bS[10], bS[11]);
                bS[2] = bS[7][bS[9]];
                bS[9] = "UDim2";
                bS[8] = Env[bS[9]];
                bS[10] = r15;
                bS[11] = r16;
                bS[12] = bS[11](bS[13], bS[14]);
                bS[9] = bS[10][bS[12]];
                bS[10] = 10;
                bS[11] = 0;
                bS[12] = 0;
                bS[7] = bS[8][bS[9]];
                bS[9] = 0;
                bS[8] = bS[7](bS[9], bS[10], bS[11], bS[12]);
                bS[6][bS[2]] = bS[8];
                bS[7] = r15;
                bS[11] = 28216220955475;
                bS[8] = r16;
                bS[10] = "d\xd2\xe6\x07Y\xd2\xdc\x0f#\x147\xeb\x8d!\xceo\xf5F0m\x8c\x87";
                bS[9] = bS[8](bS[10], bS[11]);
                bS[10] = "\xd7DT\xfd";
                bS[2] = bS[7][bS[9]];
                bS[7] = 1;
                bS[11] = 35119751249889;
                bS[6][bS[2]] = bS[7];
                bS[16] = 30889842948144;
                bS[7] = r15;
                bS[8] = r16;
                bS[9] = bS[8](bS[10], bS[11]);
                bS[2] = bS[7][bS[9]];
                bS[12] = 3474778179154;
                bS[11] = "\xc6\xfan\xc4\xd2_s\xc6\x0f\xed\x02\xb2\x0b\x9f1-\x9a\xb5h%1\xafL\x1e\xa4";
                bS[8] = r15;
                bS[9] = r16;
                bS[10] = bS[9](bS[11], bS[12]);
                bS[7] = bS[8][bS[10]];
                bS[6][bS[2]] = bS[7];
                bS[7] = r15;
                bS[14] = 15052083714913;
                bS[11] = 13757619034374;
                bS[8] = r16;
                bS[10] = "g]\xcd\x0frV)\x05\x1f[";
                bS[9] = bS[8](bS[10], bS[11]);
                bS[2] = bS[7][bS[9]];
                bS[9] = "Color3";
                bS[8] = Env[bS[9]];
                bS[10] = r15;
                bS[13] = "\xef\t\x8aN\xff\x1bB";
                bS[11] = r16;
                bS[12] = bS[11](bS[13], bS[14]);
                bS[9] = bS[10][bS[12]];
                bS[14] = "g\xc9\xc7\x12&<R\t\x0e\x1e\x9a\xed(\xb9";
                bS[11] = 240;
                bS[7] = bS[8][bS[9]];
                bS[10] = 180;
                bS[9] = 210;
                bS[8] = bS[7](bS[9], bS[10], bS[11]);
                bS[6][bS[2]] = bS[8];
                bS[10] = "C\x02\xf7\x97\xb1\xed9\xfd";
                bS[7] = r15;
                bS[8] = r16;
                bS[11] = 5490055301628;
                bS[9] = bS[8](bS[10], bS[11]);
                bS[10] = "\x18\xef/\x9cV6z\x93\xfaK\xa6\xa0R)";
                bS[2] = bS[7][bS[9]];
                bS[11] = 14892059482902;
                bS[7] = 14;
                bS[6][bS[2]] = bS[7];
                bS[7] = r15;
                bS[8] = r16;
                bS[9] = bS[8](bS[10], bS[11]);
                bS[2] = bS[7][bS[9]];
                bS[10] = "Enum";
                bS[9] = Env[bS[10]];
                bS[11] = r15;
                bS[12] = r16;
                bS[13] = bS[12](bS[14], bS[15]);
                bS[10] = bS[11][bS[13]];
                bS[15] = 2695887750375;
                bS[8] = bS[9][bS[10]];
                bS[10] = r15;
                bS[13] = "}TSZ";
                bS[14] = 10161541862011;
                bS[11] = r16;
                bS[12] = bS[11](bS[13], bS[14]);
                bS[9] = bS[10][bS[12]];
                bS[14] = "I\xad^{";
                bS[11] = 509373776109;
                bS[7] = bS[8][bS[9]];
                bS[6][bS[2]] = bS[7];
                bS[7] = r15;
                bS[10] = "\xb5\xefb\xcd";
                bS[8] = r16;
                bS[9] = bS[8](bS[10], bS[11]);
                bS[2] = bS[7][bS[9]];
                bS[10] = "Enum";
                bS[9] = Env[bS[10]];
                bS[11] = r15;
                bS[12] = r16;
                bS[13] = bS[12](bS[14], bS[15]);
                bS[10] = bS[11][bS[13]];
                bS[14] = 7883908222551;
                bS[13] = "\x93\x89\x1e\x91\xb3\x89B\x9d:\xf4\x0bp";
                bS[8] = bS[9][bS[10]];
                bS[10] = r15;
                bS[11] = r16;
                bS[12] = bS[11](bS[13], bS[14]);
                bS[9] = bS[10][bS[12]];
                bS[11] = 12568701261532;
                bS[7] = bS[8][bS[9]];
                bS[10] = "\xd3\xb6n\xf9FD";
                bS[6][bS[2]] = bS[7];
                bS[7] = r15;
                bS[8] = r16;
                bS[9] = bS[8](bS[10], bS[11]);
                bS[2] = bS[7][bS[9]];
                bS[8] = "Instance";
                bS[7] = bS[5];
                bS[12] = "%\xcc\xf9";
                bS[13] = 18002727461055;
                bS[6][bS[2]] = bS[7];
                bS[7] = Env[bS[8]];
                bS[9] = r15;
                bS[10] = r16;
                bS[11] = bS[10](bS[12], bS[13]);
                bS[8] = bS[9][bS[11]];
                bS[2] = bS[7][bS[8]];
                bS[13] = 18051535823061;
                bS[12] = "\x14\xc5\xaf\xee1";
                bS[9] = r15;
                bS[10] = r16;
                bS[11] = bS[10](bS[12], bS[13]);
                bS[8] = bS[9][bS[11]];
                bS[7] = bS[2](bS[8]);
                bS[15] = "Il\xca";
                bS[12] = "m1\xed2";
                bS[2] = 23;
                bS[13] = 21487995610902;
                o[bS[2]] = bS[7];
                bS[7] = o[bS[2]];
                bS[14] = 23228757224000;
                bS[9] = r15;
                bS[10] = r16;
                bS[11] = bS[10](bS[12], bS[13]);
                bS[8] = bS[9][bS[11]];
                bS[10] = r15;
                bS[11] = r16;
                bS[13] = "\xab\xc5\xb5\xebn\xed\x025\xafS";
                bS[12] = bS[11](bS[13], bS[14]);
                bS[9] = bS[10][bS[12]];
                bS[7][bS[8]] = bS[9];
                bS[7] = o[bS[2]];
                bS[12] = "9j\xed\xdf";
                bS[9] = r15;
                bS[10] = r16;
                bS[13] = 14794668776169;
                bS[11] = bS[10](bS[12], bS[13]);
                bS[8] = bS[9][bS[11]];
                bS[11] = "UDim2";
                bS[10] = Env[bS[11]];
                bS[12] = r15;
                bS[13] = r16;
                bS[14] = bS[13](bS[15], bS[16]);
                bS[11] = bS[12][bS[14]];
                bS[12] = 40;
                bS[9] = bS[10][bS[11]];
                bS[11] = 0;
                bS[14] = 20;
                bS[13] = 0;
                bS[10] = bS[9](bS[11], bS[12], bS[13], bS[14]);
                bS[7][bS[8]] = bS[10];
                bS[16] = 12791296776004;
                bS[13] = 6385425828765;
                bS[7] = o[bS[2]];
                bS[9] = r15;
                bS[10] = r16;
                bS[15] = "j\xe9\x9f";
                bS[12] = "q\x08\xaf\xbf\xbf0\xbd\x94";
                bS[11] = bS[10](bS[12], bS[13]);
                bS[8] = bS[9][bS[11]];
                bS[11] = "UDim2";
                bS[10] = Env[bS[11]];
                bS[12] = r15;
                bS[13] = r16;
                bS[14] = bS[13](bS[15], bS[16]);
                bS[11] = bS[12][bS[14]];
                bS[14] = -10;
                bS[12] = -45;
                bS[13] = 0.5;
                bS[9] = bS[10][bS[11]];
                bS[11] = 1;
                bS[10] = bS[9](bS[11], bS[12], bS[13], bS[14]);
                bS[7][bS[8]] = bS[10];
                bS[13] = 32170042440324;
                bS[7] = o[bS[2]];
                bS[9] = r15;
                bS[10] = r16;
                bS[12] = "\xcf\x0c\x9e\x8b\xfb\xbf}\xee&\xf4\xc5\xf9\xc5\xc7=\xa7";
                bS[11] = bS[10](bS[12], bS[13]);
                bS[8] = bS[9][bS[11]];
                bS[12] = false;
                bS[10] = false;
                bS[13] = r37;
                bS[11] = bS[13];
                bS[9] = bS[11] and bS[14];
                v8 = bS[12];
                if bS[11] then
                    bS[13] = 32052400437837;
                    v8 = bS[10];
                    bS[7][bS[8]] = bS[9];
                    bS[7] = o[bS[2]];
                    bS[12] = "k\xa0F\xfbX\xce\xe6\xd1\x97\x16:\xdb#\x9aM8";
                    bS[9] = r15;
                    bS[10] = r16;
                    bS[11] = bS[10](bS[12], bS[13]);
                    bS[12] = "\xbc\x82X\xfe\x1c\xbc";
                    bS[8] = bS[9][bS[11]];
                    bS[18] = 17085619379988;
                    bS[9] = true;
                    bS[7][bS[8]] = bS[9];
                    bS[7] = o[bS[2]];
                    bS[9] = r15;
                    bS[10] = r16;
                    bS[13] = 8696843587537;
                    bS[11] = bS[10](bS[12], bS[13]);
                    bS[8] = bS[9][bS[11]];
                    bS[15] = "\xef\x8b\xc1";
                    bS[9] = 16;
                    bS[14] = 21351650567894;
                    bS[7][bS[8]] = bS[9];
                    bS[7] = o[bS[2]];
                    bS[12] = "3\xadP\xc75\x07";
                    bS[16] = 27226474312070;
                    bS[9] = r15;
                    bS[10] = r16;
                    bS[13] = 3731418826441;
                    bS[11] = bS[10](bS[12], bS[13]);
                    bS[8] = bS[9][bS[11]];
                    bS[9] = bS[5];
                    bS[7][bS[8]] = bS[9];
                    bS[9] = "Instance";
                    bS[8] = Env[bS[9]];
                    bS[10] = r15;
                    bS[13] = "\xf2\xe6C";
                    bS[11] = r16;
                    bS[12] = bS[11](bS[13], bS[14]);
                    bS[9] = bS[10][bS[12]];
                    bS[14] = 30588464101283;
                    bS[13] = "\x16\xf6\x99\x0c\xdeM>\xe0";
                    bS[7] = bS[8][bS[9]];
                    bS[10] = r15;
                    bS[11] = r16;
                    bS[12] = bS[11](bS[13], bS[14]);
                    bS[9] = bS[10][bS[12]];
                    bS[8] = bS[7](bS[9]);
                    bS[13] = 31133316905121;
                    bS[12] = "\xd9|\xabP\x8f\r\xa3%r\n\r\x95";
                    bS[9] = r15;
                    bS[10] = r16;
                    bS[11] = bS[10](bS[12], bS[13]);
                    bS[7] = bS[9][bS[11]];
                    bS[11] = "UDim";
                    bS[10] = Env[bS[11]];
                    bS[12] = r15;
                    bS[13] = r16;
                    bS[14] = bS[13](bS[15], bS[16]);
                    bS[15] = 31068696049795;
                    bS[11] = bS[12][bS[14]];
                    bS[9] = bS[10][bS[11]];
                    bS[12] = 0;
                    bS[11] = 1;
                    bS[10] = bS[9](bS[11], bS[12]);
                    bS[8][bS[7]] = bS[10];
                    bS[9] = r15;
                    bS[13] = 23620312951543;
                    bS[12] = "0\x84\xed2\xf64";
                    bS[10] = r16;
                    bS[11] = bS[10](bS[12], bS[13]);
                    bS[14] = "\xfa\xb3\x01";
                    bS[7] = bS[9][bS[11]];
                    bS[10] = "Instance";
                    bS[9] = o[bS[2]];
                    bS[8][bS[7]] = bS[9];
                    bS[9] = Env[bS[10]];
                    bS[11] = r15;
                    bS[12] = r16;
                    bS[13] = bS[12](bS[14], bS[15]);
                    bS[10] = bS[11][bS[13]];
                    bS[7] = bS[9][bS[10]];
                    bS[14] = "\x05\xfc]\xd2\x1f";
                    bS[11] = r15;
                    bS[15] = 30701252507608;
                    bS[12] = r16;
                    bS[13] = bS[12](bS[14], bS[15]);
                    bS[10] = bS[11][bS[13]];
                    bS[9] = bS[7](bS[10]);
                    bS[14] = "\xb5B\xf6\xf2";
                    bS[7] = 196;
                    bS[16] = 10936407675876;
                    o[bS[7]] = bS[9];
                    bS[9] = o[bS[7]];
                    bS[11] = r15;
                    bS[15] = 2193559897085;
                    bS[12] = r16;
                    bS[13] = bS[12](bS[14], bS[15]);
                    bS[10] = bS[11][bS[13]];
                    bS[12] = r15;
                    bS[15] = "\x1f9\x8f\x95\xbc:\xa9\xeb";
                    bS[17] = "\xa5[\xb4";
                    bS[13] = r16;
                    bS[14] = bS[13](bS[15], bS[16]);
                    bS[11] = bS[12][bS[14]];
                    bS[9][bS[10]] = bS[11];
                    bS[9] = o[bS[7]];
                    bS[11] = r15;
                    bS[15] = 1006935704020;
                    bS[12] = r16;
                    bS[14] = "+\x7fr\xd1";
                    bS[13] = bS[12](bS[14], bS[15]);
                    bS[10] = bS[11][bS[13]];
                    bS[13] = "UDim2";
                    bS[12] = Env[bS[13]];
                    bS[14] = r15;
                    bS[15] = r16;
                    bS[16] = bS[15](bS[17], bS[18]);
                    bS[13] = bS[14][bS[16]];
                    bS[11] = bS[12][bS[13]];
                    bS[16] = -4;
                    bS[14] = -2;
                    bS[15] = 1;
                    bS[13] = 0.5;
                    bS[12] = bS[11](bS[13], bS[14], bS[15], bS[16]);
                    bS[9][bS[10]] = bS[12];
                    bS[14] = "Wm\xe1\xc5;\x05\x05\xa4";
                    bS[9] = o[bS[7]];
                    bS[11] = r15;
                    bS[15] = 23479757089461;
                    bS[12] = r16;
                    bS[13] = bS[12](bS[14], bS[15]);
                    bS[12] = v8;
                    bS[10] = bS[11][bS[13]];
                    bS[15] = r37;
                    bS[14] = v8;
                    bS[13] = bS[15];
                    if bS[15] then
                        bS[17] = "UDim2";
                        bS[22] = 11168477582416;
                        bS[16] = Env[bS[17]];
                        bS[21] = "\xf7\xf1l";
                        bS[18] = r15;
                        bS[19] = r16;
                        bS[20] = bS[19](bS[21], bS[22]);
                        bS[17] = bS[18][bS[20]];
                        bS[19] = 0;
                        bS[15] = bS[16][bS[17]];
                        bS[20] = 2;
                        bS[18] = 1;
                        bS[17] = 0.5;
                        bS[16] = bS[15](bS[17], bS[18], bS[19], bS[20]);
                        bS[13] = bS[16];
                    end;
                    v8 = bS[14];
                    bS[11] = bS[13];
                    if bS[13] then
                        bS[31] = 5778592205442;
                        v8 = bS[12];
                        bS[9][bS[10]] = bS[11];
                        bS[17] = "\xa7i\xb2";
                        bS[14] = "\x04\xc2U&\x1c[\x87\xd7\x98\xa2\xac\xe8\xc5\x00x\\";
                        bS[9] = o[bS[7]];
                        bS[11] = r15;
                        bS[12] = r16;
                        bS[15] = 26175644839836;
                        bS[18] = 19052385804967;
                        bS[13] = bS[12](bS[14], bS[15]);
                        bS[10] = bS[11][bS[13]];
                        bS[13] = "Color3";
                        bS[12] = Env[bS[13]];
                        bS[14] = r15;
                        bS[15] = r16;
                        bS[16] = bS[15](bS[17], bS[18]);
                        bS[13] = bS[14][bS[16]];
                        bS[11] = bS[12][bS[13]];
                        bS[15] = 1;
                        bS[13] = 1;
                        bS[14] = 1;
                        bS[12] = bS[11](bS[13], bS[14], bS[15]);
                        bS[14] = "\x89 r\x02\xdd\xa4";
                        bS[15] = 30163694417630;
                        bS[9][bS[10]] = bS[12];
                        bS[9] = o[bS[7]];
                        bS[11] = r15;
                        bS[19] = "J\xe3\xc2";
                        bS[12] = r16;
                        bS[13] = bS[12](bS[14], bS[15]);
                        bS[10] = bS[11][bS[13]];
                        bS[11] = 17;
                        bS[14] = "\x9a\x14\x92\x7f\xaf\xfd";
                        bS[9][bS[10]] = bS[11];
                        bS[15] = 8994000212060;
                        bS[9] = o[bS[7]];
                        bS[11] = r15;
                        bS[12] = r16;
                        bS[16] = 1919549522813;
                        bS[13] = bS[12](bS[14], bS[15]);
                        bS[24] = 7546535022010;
                        bS[10] = bS[11][bS[13]];
                        bS[11] = o[bS[2]];
                        bS[15] = "\xe4Q\xd3";
                        bS[9][bS[10]] = bS[11];
                        bS[11] = "Instance";
                        bS[10] = Env[bS[11]];
                        bS[12] = r15;
                        bS[13] = r16;
                        bS[14] = bS[13](bS[15], bS[16]);
                        bS[16] = 16467317923316;
                        bS[11] = bS[12][bS[14]];
                        bS[15] = "\xf2\x14/\xcb\xe4\x1e\xb0k";
                        bS[9] = bS[10][bS[11]];
                        bS[12] = r15;
                        bS[13] = r16;
                        bS[14] = bS[13](bS[15], bS[16]);
                        bS[17] = "\xa4\xf0\xbf";
                        bS[15] = 32222757436060;
                        bS[11] = bS[12][bS[14]];
                        bS[10] = bS[9](bS[11]);
                        bS[14] = "X&M\x87o\xc8\xe2\xef=\xc5Xn";
                        bS[18] = 16714218298983;
                        bS[11] = r15;
                        bS[12] = r16;
                        bS[13] = bS[12](bS[14], bS[15]);
                        bS[9] = bS[11][bS[13]];
                        bS[13] = "UDim";
                        bS[12] = Env[bS[13]];
                        bS[34] = 28626849117202;
                        bS[14] = r15;
                        bS[15] = r16;
                        bS[22] = 31793511004629;
                        bS[16] = bS[15](bS[17], bS[18]);
                        bS[18] = 15793149516986;
                        bS[13] = bS[14][bS[16]];
                        bS[14] = 0;
                        bS[11] = bS[12][bS[13]];
                        bS[15] = 12172788766244;
                        bS[13] = 1;
                        bS[12] = bS[11](bS[13], bS[14]);
                        bS[10][bS[9]] = bS[12];
                        bS[11] = r15;
                        bS[14] = "\xc6\x89I\xb5Z\x13";
                        bS[12] = r16;
                        bS[13] = bS[12](bS[14], bS[15]);
                        bS[9] = bS[11][bS[13]];
                        bS[17] = 3423811159610;
                        bS[11] = o[bS[7]];
                        bS[10][bS[9]] = bS[11];
                        bS[11] = o[bS[2]];
                        bS[13] = r15;
                        bS[16] = "q\x8eZ}8y\xcc\x84\x90j";
                        bS[14] = r16;
                        bS[15] = bS[14](bS[16], bS[17]);
                        bS[12] = bS[13][bS[15]];
                        bS[9] = bS[11][bS[12]];
                        bS[11] = "Connect";
                        bS[12] = function(arg1_33, ...)
                            P = r15;
                            if arg1_33.UserInputType == Enum.UserInputType.MouseButton1 then
                                v8 = not r37;
                                r37 = v8;
                                r86();
                                S = v8;
                                P = r37;
                                if P then
                                    N = Color3.fromRGB(160, 100, 220);
                                end;
                                v8 = v8;
                                v3 = P;
                                if P then
                                    v4 = r37;
                                    S = N;
                                    q = v4;
                                    N = v8;
                                    if v4 then
                                        q = UDim2.new(0.5, 1, 0, 2);
                                    end;
                                    v8 = v8;
                                    v3 = q;
                                    if q then
                                        v8 = v8;
                                        N = v3.Create(v3, o[bS[7]], TweenInfo.new(.3), {
                                            ["Position"] = N
                                        });
                                        v3 = r27;
                                        q = v3.Create(v3, o[bS[2]], TweenInfo.new(.3), {
                                            ["BackgroundColor3"] = N
                                        });
                                        q.Play(q);
                                        v3 = r27;
                                        q = v3.Create(v3, o[bS[7]], TweenInfo.new(.3), {
                                            ["Position"] = N
                                        });
                                        q.Play(q);
                                        return;
                                    else
                                        v3 = UDim2.new(0, 2, 0, 2);
                                    end;
                                else
                                    v3 = Color3.fromRGB(100, 100, 100);
                                end;
                            end; 
                        end;
                        bS[16] = "\x06\x80\xa6";
                        bS[11] = bS[9][bS[11]];
                        bS[11] = bS[11](bS[9], bS[12]);
                        bS[12] = "Instance";
                        bS[11] = Env[bS[12]];
                        bS[13] = r15;
                        bS[14] = r16;
                        bS[17] = 13599589619900;
                        bS[15] = bS[14](bS[16], bS[17]);
                        bS[16] = "\xd6\x85\xfe\xa1\xa9";
                        bS[12] = bS[13][bS[15]];
                        bS[9] = bS[11][bS[12]];
                        bS[17] = 26491496312880;
                        bS[13] = r15;
                        bS[14] = r16;
                        bS[15] = bS[14](bS[16], bS[17]);
                        bS[12] = bS[13][bS[15]];
                        bS[11] = bS[9](bS[12]);
                        bS[9] = 11;
                        o[bS[9]] = bS[11];
                        bS[17] = 14937120643883;
                        bS[11] = o[bS[9]];
                        bS[16] = "\x0f\xfd\xc3\x12";
                        bS[13] = r15;
                        bS[14] = r16;
                        bS[15] = bS[14](bS[16], bS[17]);
                        bS[12] = bS[13][bS[15]];
                        bS[17] = "\xa4\xb63\xb7\x0f\x9a\xec\\\xf1F\x1b\xa9\x8c\xfe\xffT\xbd\x80uM\xd65u";
                        bS[14] = r15;
                        bS[15] = r16;
                        bS[16] = bS[15](bS[17], bS[18]);
                        bS[17] = 2243531883540;
                        bS[13] = bS[14][bS[16]];
                        bS[11][bS[12]] = bS[13];
                        bS[16] = "\xbd\xe5\xa0\xb4";
                        bS[20] = 15944056347904;
                        bS[11] = o[bS[9]];
                        bS[13] = r15;
                        bS[14] = r16;
                        bS[21] = 18909393429093;
                        bS[15] = bS[14](bS[16], bS[17]);
                        bS[12] = bS[13][bS[15]];
                        bS[15] = "UDim2";
                        bS[14] = Env[bS[15]];
                        bS[16] = r15;
                        bS[17] = r16;
                        bS[18] = bS[17](bS[19], bS[20]);
                        bS[15] = bS[16][bS[18]];
                        bS[16] = 0;
                        bS[13] = bS[14][bS[15]];
                        bS[18] = 350;
                        bS[17] = 0;
                        bS[15] = 1;
                        bS[14] = bS[13](bS[15], bS[16], bS[17], bS[18]);
                        bS[11][bS[12]] = bS[14];
                        bS[11] = o[bS[9]];
                        bS[16] = ":a\xdcIf\xf4P\x1a\xf7W\xbb\x1f\xba\x9a*\xc7s\xae\x7f\x0ccm";
                        bS[13] = r15;
                        bS[17] = 32878768896974;
                        bS[14] = r16;
                        bS[15] = bS[14](bS[16], bS[17]);
                        bS[17] = 25723288973002;
                        bS[18] = 15289389947855;
                        bS[12] = bS[13][bS[15]];
                        bS[16] = "l\xb4\x7f\x15o\xfa#\xccbb\x91";
                        bS[13] = 1;
                        bS[11][bS[12]] = bS[13];
                        bS[11] = o[bS[9]];
                        bS[13] = r15;
                        bS[14] = r16;
                        bS[15] = bS[14](bS[16], bS[17]);
                        bS[12] = bS[13][bS[15]];
                        bS[17] = 27112533930321;
                        bS[13] = 3;
                        bS[11][bS[12]] = bS[13];
                        bS[11] = o[bS[9]];
                        bS[13] = r15;
                        bS[14] = r16;
                        bS[16] = "\x93\xd5\x80\xe6\xff\xaf";
                        bS[15] = bS[14](bS[16], bS[17]);
                        bS[12] = bS[13][bS[15]];
                        bS[20] = 12900097152887;
                        bS[13] = r144;
                        bS[19] = ")\n\x19";
                        bS[11][bS[12]] = bS[13];
                        bS[13] = "Instance";
                        bS[17] = "m\x13\x1d";
                        bS[12] = Env[bS[13]];
                        bS[14] = r15;
                        bS[15] = r16;
                        bS[16] = bS[15](bS[17], bS[18]);
                        bS[18] = 16714561724007;
                        bS[13] = bS[14][bS[16]];
                        bS[11] = bS[12][bS[13]];
                        bS[14] = r15;
                        bS[17] = "\xa2b\x8cM\xa9'\xbb1\xe1";
                        bS[15] = r16;
                        bS[16] = bS[15](bS[17], bS[18]);
                        bS[13] = bS[14][bS[16]];
                        bS[12] = bS[11](bS[13]);
                        bS[16] = "\xf2\xdb\x0b\xfa";
                        bS[13] = r15;
                        bS[17] = 10980547630073;
                        bS[14] = r16;
                        bS[18] = 10268712276653;
                        bS[15] = bS[14](bS[16], bS[17]);
                        bS[11] = bS[13][bS[15]];
                        bS[17] = "\x9c\x02\xfc\x03\xff";
                        bS[14] = r15;
                        bS[15] = r16;
                        bS[23] = 10967324267507;
                        bS[16] = bS[15](bS[17], bS[18]);
                        bS[13] = bS[14][bS[16]];
                        bS[12][bS[11]] = bS[13];
                        bS[13] = r15;
                        bS[16] = " h\xfdL";
                        bS[14] = r16;
                        bS[17] = 25708561936067;
                        bS[15] = bS[14](bS[16], bS[17]);
                        bS[11] = bS[13][bS[15]];
                        bS[15] = "UDim2";
                        bS[14] = Env[bS[15]];
                        bS[16] = r15;
                        bS[17] = r16;
                        bS[18] = bS[17](bS[19], bS[20]);
                        bS[19] = "s\x9d9";
                        bS[15] = bS[16][bS[18]];
                        bS[17] = 0;
                        bS[16] = 0;
                        bS[13] = bS[14][bS[15]];
                        bS[15] = 1;
                        bS[18] = 30;
                        bS[14] = bS[13](bS[15], bS[16], bS[17], bS[18]);
                        bS[16] = "\xfe\x02wsq\xb3\n\x8c";
                        bS[17] = 26736030199969;
                        bS[12][bS[11]] = bS[14];
                        bS[13] = r15;
                        bS[14] = r16;
                        bS[15] = bS[14](bS[16], bS[17]);
                        bS[11] = bS[13][bS[15]];
                        bS[15] = "UDim2";
                        bS[14] = Env[bS[15]];
                        bS[16] = r15;
                        bS[17] = r16;
                        bS[20] = 22746947266912;
                        bS[18] = bS[17](bS[19], bS[20]);
                        bS[15] = bS[16][bS[18]];
                        bS[16] = 0;
                        bS[13] = bS[14][bS[15]];
                        bS[15] = 0;
                        bS[18] = 0;
                        bS[17] = 0;
                        bS[14] = bS[13](bS[15], bS[16], bS[17], bS[18]);
                        bS[12][bS[11]] = bS[14];
                        bS[17] = 29614315468254;
                        bS[13] = r15;
                        bS[14] = r16;
                        bS[16] = "\x82A\xd9i\xc6\x03\x8a\x009\xa7\x16\xbb`\x15|4\x1b\xc68m\xd3\x8a";
                        bS[15] = bS[14](bS[16], bS[17]);
                        bS[17] = 3724446877382;
                        bS[27] = 15000745401161;
                        bS[11] = bS[13][bS[15]];
                        bS[13] = 1;
                        bS[18] = 26170758442906;
                        bS[16] = "\x87\xa3Zi";
                        bS[20] = 12882905978735;
                        bS[12][bS[11]] = bS[13];
                        bS[13] = r15;
                        bS[19] = "W\x1a\x00mW\xf2\xc3";
                        bS[14] = r16;
                        bS[15] = bS[14](bS[16], bS[17]);
                        bS[11] = bS[13][bS[15]];
                        bS[17] = "\xe1\x1aA/j,`\xce?.\xc6\x8a\x07\x06Kn\x93";
                        bS[14] = r15;
                        bS[15] = r16;
                        bS[16] = bS[15](bS[17], bS[18]);
                        bS[13] = bS[14][bS[16]];
                        bS[12][bS[11]] = bS[13];
                        bS[13] = r15;
                        bS[17] = 23935458438025;
                        bS[16] = "\xd7h\xb7c\x98wQc\xf5\xe2";
                        bS[14] = r16;
                        bS[15] = bS[14](bS[16], bS[17]);
                        bS[11] = bS[13][bS[15]];
                        bS[15] = "Color3";
                        bS[14] = Env[bS[15]];
                        bS[16] = r15;
                        bS[17] = r16;
                        bS[28] = 6691489991723;
                        bS[18] = bS[17](bS[19], bS[20]);
                        bS[15] = bS[16][bS[18]];
                        bS[13] = bS[14][bS[15]];
                        bS[16] = 200;
                        bS[17] = 255;
                        bS[15] = 230;
                        bS[14] = bS[13](bS[15], bS[16], bS[17]);
                        bS[12][bS[11]] = bS[14];
                        bS[16] = "\x9d\n7\xb9Z\xb8RP";
                        bS[13] = r15;
                        bS[17] = 12049099494890;
                        bS[20] = "J&\xb4\xd2";
                        bS[14] = r16;
                        bS[15] = bS[14](bS[16], bS[17]);
                        bS[11] = bS[13][bS[15]];
                        bS[13] = 16;
                        bS[12][bS[11]] = bS[13];
                        bS[13] = r15;
                        bS[17] = 19677895058379;
                        bS[14] = r16;
                        bS[16] = "\x16\x1a\x93\n";
                        bS[15] = bS[14](bS[16], bS[17]);
                        bS[16] = "Enum";
                        bS[11] = bS[13][bS[15]];
                        bS[15] = Env[bS[16]];
                        bS[17] = r15;
                        bS[18] = r16;
                        bS[19] = bS[18](bS[20], bS[21]);
                        bS[16] = bS[17][bS[19]];
                        bS[14] = bS[15][bS[16]];
                        bS[16] = r15;
                        bS[17] = r16;
                        bS[20] = 6624284150796;
                        bS[19] = "\x9b:%y\x8c#\xa2h\xa9\xe5";
                        bS[18] = bS[17](bS[19], bS[20]);
                        bS[15] = bS[16][bS[18]];
                        bS[16] = "\x8e\xf7\xe1\xe0\xb8\x81";
                        bS[13] = bS[14][bS[15]];
                        bS[17] = 19151750521558;
                        bS[12][bS[11]] = bS[13];
                        bS[13] = r15;
                        bS[14] = r16;
                        bS[20] = 13555483777192;
                        bS[18] = "\xb6'\xaf\xc24\x10\xe7\xd6\x9d";
                        bS[15] = bS[14](bS[16], bS[17]);
                        bS[11] = bS[13][bS[15]];
                        bS[19] = 11121803351098;
                        bS[13] = o[bS[9]];
                        bS[12][bS[11]] = bS[13];
                        bS[15] = r15;
                        bS[16] = r16;
                        bS[11] = function(arg1_34, arg2_34, arg3_34, arg4_34, ...)
                            r178 = arg1_34;
                            N = arg3_34;
                            P = Instance.new("Frame");
                            P.Name = r178 .. "Container";
                            P.Size = UDim2.new(1, 0, 0, 80);
                            P.Position = UDim2.new(0, 0, 0, arg4_34);
                            P.BackgroundTransparency = 1;
                            P.Parent = o[bS[9]];
                            v4 = Instance.new("TextLabel");
                            v4.Name = "Label";
                            v4.Size = UDim2.new(.6, 0, 0.25, 0);
                            v4.Position = UDim2.new(0, 0, 0, 0);
                            v4.BackgroundTransparency = 1;
                            v3 = arg2_34;
                            v4.Text = v3;
                            v4.TextColor3 = Color3.fromRGB(210, 180, 240);
                            v4.TextSize = 14;
                            v4.TextXAlignment = Enum.TextXAlignment.Left;
                            v4.Font = Enum.Font.GothamMedium;
                            v4.Parent = P;
                            v2 = Instance.new("Frame");
                            v2.Name = "TextInputContainer";
                            v2.Size = UDim2.new(.3, 0, 0.25, 0);
                            v2.Position = UDim2.new(.7, 0, 0, 0);
                            v2.BackgroundColor3 = Color3.fromRGB(40, 25, 60);
                            v2.BackgroundTransparency = .1;
                            v2.Parent = P;
                            v7 = Instance.new("UICorner");
                            v7.CornerRadius = UDim.new(0, 6);
                            v7.Parent = v2;
                            r179 = Instance.new("TextBox");
                            r179.Name = "TextInput";
                            r179.Size = UDim2.new(1, -10, 1, -10);
                            r179.Position = UDim2.new(0, 5, 0, 5);
                            r179.BackgroundTransparency = 1;
                            r179.Text = string.format("%.2f", N);
                            r179.TextColor3 = Color3.fromRGB(250, 230, 255);
                            r179.TextSize = 14;
                            r179.Font = Enum.Font.GothamBold;
                            r179.PlaceholderText = "Enter multiplier...";
                            r179.PlaceholderColor3 = Color3.fromRGB(150, 130, 180);
                            r179.ClearTextOnFocus = false;
                            r179.Parent = v2;
                            K = Instance.new("ImageLabel");
                            K.Size = UDim2.new(1, 8, 1, 8);
                            K.Position = UDim2.new(0, -4, 0, -4);
                            K.BackgroundTransparency = 1;
                            K.Image = "rbxassetid://5028857084";
                            K.ImageColor3 = Color3.fromRGB(100, 200, 255);
                            K.ImageTransparency = .7;
                            K.ScaleType = Enum.ScaleType.Slice;
                            K.SliceCenter = Rect.new(24, 24, 276, 276);
                            K.ZIndex = -1;
                            K.Parent = v2;
                            v6 = Instance.new("TextLabel");
                            v6.Name = "InfoLabel";
                            v6.Size = UDim2.new(1, 0, .2, 0);
                            v6.Position = UDim2.new(0, 0, 0.25, 0);
                            v6.BackgroundTransparency = 1;
                            v6.Text = "Enter any positive value (e.g., 0.1, 1.5, 100)";
                            v6.TextColor3 = Color3.fromRGB(180, 200, 240);
                            v6.TextSize = 11;
                            v6.TextXAlignment = Enum.TextXAlignment.Left;
                            v6.Font = Enum.Font.Gotham;
                            v6.Parent = P;
                            r = Instance.new("Frame");
                            r.Name = "SliderContainer";
                            r.Size = UDim2.new(1, 0, .35, 0);
                            r.Position = UDim2.new(0, 0, .45, 0);
                            r.BackgroundTransparency = 1;
                            r.Parent = P;
                            r180 = Instance.new("Frame");
                            r180.Name = "SliderTrack";
                            r180.Size = UDim2.new(1, 0, 0, 8);
                            r180.Position = UDim2.new(0, 0, 0.5, -4);
                            r180.BackgroundColor3 = Color3.fromRGB(50, 30, 70);
                            r180.Parent = r;
                            v10 = Instance.new("UICorner");
                            v10.CornerRadius = UDim.new(0.5, 0);
                            v10.Parent = r180;
                            r181 = Instance.new("Frame");
                            r181.Name = "SliderFill";
                            r181.Size = UDim2.new(math.min(N / 10, 1), 0, 1, 0);
                            r181.Position = UDim2.new(0, 0, 0, 0);
                            r181.BackgroundColor3 = Color3.fromRGB(100, 200, 255);
                            r181.Parent = r180;
                            F = Instance.new("UICorner");
                            F.CornerRadius = UDim.new(0.5, 0);
                            F.Parent = r181;
                            J = Instance.new("ImageLabel");
                            J.Size = UDim2.new(1, 12, 1, 12);
                            J.Position = UDim2.new(0, -6, 0, -6);
                            J.BackgroundTransparency = 1;
                            J.Image = "rbxassetid://5028857084";
                            J.ImageColor3 = Color3.fromRGB(100, 200, 255);
                            J.ImageTransparency = .7;
                            J.ScaleType = Enum.ScaleType.Slice;
                            J.SliceCenter = Rect.new(24, 24, 276, 276);
                            J.ZIndex = -1;
                            J.Parent = r181;
                            r182 = Instance.new("TextLabel");
                            r182.Name = "ValueDisplay";
                            r182.Size = UDim2.new(.2, 0, .35, 0);
                            r182.Position = UDim2.new(.8, 0, .45, 0);
                            r182.BackgroundTransparency = 1;
                            r182.Text = "x" .. string.format("%.2f", N);
                            r182.TextColor3 = Color3.fromRGB(200, 230, 255);
                            r182.TextSize = 12;
                            r182.Font = Enum.Font.GothamMedium;
                            r182.Parent = P;
                            local function r183(arg1_35, ...)
                                v8 = math.max;
                                N = math.max;
                                v1 = v8(tonumber(arg1_35) or .01, .01);
                                q = r27;
                                P = q.Create(q, r181, TweenInfo.new(.1), {
                                    ["Size"] = UDim2.new(math.clamp(math.min(v1, 10) / 10, 0, 1), 0, 1, 0)
                                });
                                P.Play(P);
                                r179.Text = string.format("%.2f", v1);
                                v8 = v8;
                                v8 = v8;
                                r182.Text = "x" .. string.format(v1 >= 100 and "%.0f" or "%.2f", v1);
                                q = r178 == "BaseSpeed";
                                if q then
                                    q = v3;
                                    r33 = q;
                                else
                                    if r178 == "Boost1" then
                                        r182 = v3;
                                    else
                                        if r178 == "Boost2" then
                                            r178 = v3;
                                        else
                                            if r178 == "Boost3" then
                                                r33 = v3;
                                            end;
                                            r86();
                                            o[bS[20]]();
                                            return;
                                        end;
                                    end;
                                end; 
                            end;
                            r184 = false;
                            local function r185(arg1_36, ...)
                                S = r180.AbsoluteSize.X;
                                r183(math.clamp(arg1_36 - r180.AbsolutePosition.X, 0, S) / S * 10);
                                return; 
                            end;
                            v8 = r180.InputBegan;
                            v8.Connect(v8, function(arg1_37, ...)
                                v1 = arg1_37;
                                if v1.UserInputType == Enum.UserInputType.MouseButton1 then
                                    r184 = true;
                                    r185(v1.Position.X);
                                end;
                                return; 
                            end);
                            v8 = r180.InputChanged;
                            v8.Connect(v8, function(arg1_38, ...)
                                v1 = arg1_38;
                                if v1.UserInputType == Enum.UserInputType.MouseMovement and r184 then
                                    r185(v1.Position.X);
                                end;
                                return; 
                            end);
                            v8 = r180.InputEnded;
                            v8.Connect(v8, function(arg1_39, ...)
                                if arg1_39.UserInputType == Enum.UserInputType.MouseButton1 then
                                    r184 = false;
                                end;
                                return; 
                            end);
                            v8 = r179.FocusLost;
                            v8.Connect(v8, function(arg1_40, ...)
                                v1 = arg1_40;
                                N = tonumber(r179.Text);
                                if N then
                                    r183(N);
                                else
                                    q = 1;
                                    if r178 == "BaseSpeed" then
                                        q = r178;
                                    else
                                        if r178 == "Boost1" then
                                            q = r33;
                                        else
                                            if r178 == "Boost2" then
                                                q = r34;
                                            else
                                                if r178 == "Boost3" then
                                                    q = r35;
                                                end;
                                                r179.Text = string.format("%.2f", 1);
                                                return;
                                            end;
                                        end;
                                    end;
                                end; 
                            end);
                            v8 = v2.InputBegan;
                            v8.Connect(v8, function(arg1_41, ...)
                                v8 = arg1_41.UserInputType == Enum.UserInputType.MouseButton1;
                                if v8 then
                                    v8 = r179;
                                    v8.CaptureFocus(v8);
                                end;
                                return; 
                            end);
                            r181.Size = UDim2.new(math.clamp(math.min(N, 10) / 10, 0, 1), 0, 1, 0);
                            return P; 
                        end;
                        bS[17] = bS[16](bS[18], bS[19]);
                        bS[14] = bS[15][bS[17]];
                        bS[16] = r15;
                        bS[17] = r16;
                        bS[19] = "!\xc2HV\xed\xb4\xd3\xe7\xc4\xc5\x00\xa7R]\x81\x19\x19\x03\xf1J\xf1";
                        bS[18] = bS[17](bS[19], bS[20]);
                        bS[15] = bS[16][bS[18]];
                        bS[20] = 30616582846384;
                        bS[18] = "Z4\xb2\xbe\x9c\x06";
                        bS[16] = r33;
                        bS[17] = 40;
                        bS[13] = bS[11](bS[14], bS[15], bS[16], bS[17]);
                        bS[15] = r15;
                        bS[16] = r16;
                        bS[19] = 21440436217599;
                        bS[17] = bS[16](bS[18], bS[19]);
                        bS[14] = bS[15][bS[17]];
                        bS[16] = r15;
                        bS[19] = "\xf0\xcc\x03A4u\xa7u\xd6\x80]F\xc2x\xc7\x02n\x16\x88\x8d\x12B";
                        bS[17] = r16;
                        bS[18] = bS[17](bS[19], bS[20]);
                        bS[15] = bS[16][bS[18]];
                        bS[19] = 6359304129425;
                        bS[17] = 120;
                        bS[16] = r34;
                        bS[13] = bS[11](bS[14], bS[15], bS[16], bS[17]);
                        bS[18] = "\x93\xa1\xd3#\xa1\x8d";
                        bS[15] = r15;
                        bS[20] = 18184941871380;
                        bS[16] = r16;
                        bS[17] = bS[16](bS[18], bS[19]);
                        bS[19] = "\xd4\x13\x8d\x84cp\xf8\x1b\xfc\x06\xa4 \xd4\r\"!\xb2\x07\x8f\xfb\x8aN\xcd";
                        bS[14] = bS[15][bS[17]];
                        bS[16] = r15;
                        bS[17] = r16;
                        bS[18] = bS[17](bS[19], bS[20]);
                        bS[15] = bS[16][bS[18]];
                        bS[17] = 200;
                        bS[16] = r35;
                        bS[13] = bS[11](bS[14], bS[15], bS[16], bS[17]);
                        bS[20] = 25670268137137;
                        bS[18] = "\xc1\xffD\x9e\x98\xcf";
                        bS[15] = r15;
                        bS[16] = r16;
                        bS[19] = 12131503838737;
                        bS[17] = bS[16](bS[18], bS[19]);
                        bS[19] = "\x03\xa2z@\xc7f\xc4\x01\xf9\xd70{\xf2\xc2{.\xafA\x95,-\x00";
                        bS[14] = bS[15][bS[17]];
                        bS[16] = r15;
                        bS[17] = r16;
                        bS[18] = bS[17](bS[19], bS[20]);
                        bS[17] = 280;
                        bS[15] = bS[16][bS[18]];
                        bS[19] = "W\xc4\x97";
                        bS[16] = r36;
                        bS[20] = 15446982663;
                        bS[13] = bS[11](bS[14], bS[15], bS[16], bS[17]);
                        bS[15] = "Instance";
                        bS[14] = Env[bS[15]];
                        bS[16] = r15;
                        bS[17] = r16;
                        bS[18] = bS[17](bS[19], bS[20]);
                        bS[15] = bS[16][bS[18]];
                        bS[20] = 7694789725695;
                        bS[13] = bS[14][bS[15]];
                        bS[16] = r15;
                        bS[17] = r16;
                        bS[19] = "a\xaa\x07\xb9d";
                        bS[18] = bS[17](bS[19], bS[20]);
                        bS[15] = bS[16][bS[18]];
                        bS[19] = 11323802064025;
                        bS[14] = bS[13](bS[15]);
                        bS[21] = "\xb7\x06f";
                        bS[15] = r15;
                        bS[20] = 7635215289827;
                        bS[18] = "\x8dsQ.";
                        bS[16] = r16;
                        bS[17] = bS[16](bS[18], bS[19]);
                        bS[13] = bS[15][bS[17]];
                        bS[16] = r15;
                        bS[19] = "\x1a\xa0=\xb40v\x08\x1f\x13\xe6\xbey\xeda";
                        bS[17] = r16;
                        bS[18] = bS[17](bS[19], bS[20]);
                        bS[15] = bS[16][bS[18]];
                        bS[14][bS[13]] = bS[15];
                        bS[15] = r15;
                        bS[18] = "\xac\xe7HZ";
                        bS[19] = 6848150260852;
                        bS[16] = r16;
                        bS[17] = bS[16](bS[18], bS[19]);
                        bS[13] = bS[15][bS[17]];
                        bS[17] = "UDim2";
                        bS[16] = Env[bS[17]];
                        bS[18] = r15;
                        bS[19] = r16;
                        bS[20] = bS[19](bS[21], bS[22]);
                        bS[17] = bS[18][bS[20]];
                        bS[15] = bS[16][bS[17]];
                        bS[19] = 0;
                        bS[18] = 0;
                        bS[20] = 200;
                        bS[17] = 1;
                        bS[16] = bS[15](bS[17], bS[18], bS[19], bS[20]);
                        bS[14][bS[13]] = bS[16];
                        bS[18] = "eE\x06\xdf(\x7f\xf7\xf8\x12\xcd\xd9\xfb1M\xd5nx\xa0\x17\t\x00\xf8";
                        bS[15] = r15;
                        bS[19] = 2677780776158;
                        bS[16] = r16;
                        bS[17] = bS[16](bS[18], bS[19]);
                        bS[18] = "\x9a\x96\x05Nb\xc92Z\xcc46";
                        bS[13] = bS[15][bS[17]];
                        bS[15] = 1;
                        bS[19] = 13883265079616;
                        bS[14][bS[13]] = bS[15];
                        bS[21] = 30278484555539;
                        bS[20] = "\x14\xe4S";
                        bS[15] = r15;
                        bS[16] = r16;
                        bS[17] = bS[16](bS[18], bS[19]);
                        bS[13] = bS[15][bS[17]];
                        bS[15] = 5;
                        bS[14][bS[13]] = bS[15];
                        bS[18] = "\xd1s\x1el*\xd3";
                        bS[15] = r15;
                        bS[16] = r16;
                        bS[19] = 33988403822035;
                        bS[22] = "\xa3\x97\x12";
                        bS[17] = bS[16](bS[18], bS[19]);
                        bS[13] = bS[15][bS[17]];
                        bS[15] = r144;
                        bS[16] = "Instance";
                        bS[14][bS[13]] = bS[15];
                        bS[15] = Env[bS[16]];
                        bS[17] = r15;
                        bS[18] = r16;
                        bS[19] = bS[18](bS[20], bS[21]);
                        bS[16] = bS[17][bS[19]];
                        bS[21] = 16619674115643;
                        bS[13] = bS[15][bS[16]];
                        bS[17] = r15;
                        bS[18] = r16;
                        bS[20] = "\xbb\xc9\x8a\xbb\xe6\xa9\xe6\xd7\xf2";
                        bS[19] = bS[18](bS[20], bS[21]);
                        bS[16] = bS[17][bS[19]];
                        bS[15] = bS[13](bS[16]);
                        bS[19] = "\xde\x94\xe6H";
                        bS[20] = 11169569313873;
                        bS[16] = r15;
                        bS[17] = r16;
                        bS[18] = bS[17](bS[19], bS[20]);
                        bS[21] = 23763668265785;
                        bS[13] = bS[16][bS[18]];
                        bS[17] = r15;
                        bS[20] = "\xcc\xe8?\x97\xa2";
                        bS[18] = r16;
                        bS[19] = bS[18](bS[20], bS[21]);
                        bS[16] = bS[17][bS[19]];
                        bS[15][bS[13]] = bS[16];
                        bS[20] = 9528506093909;
                        bS[16] = r15;
                        bS[17] = r16;
                        bS[36] = 22698095782217;
                        bS[19] = "\t\xcc\x7f\xf0";
                        bS[18] = bS[17](bS[19], bS[20]);
                        bS[13] = bS[16][bS[18]];
                        bS[18] = "UDim2";
                        bS[17] = Env[bS[18]];
                        bS[19] = r15;
                        bS[20] = r16;
                        bS[21] = bS[20](bS[22], bS[23]);
                        bS[18] = bS[19][bS[21]];
                        bS[16] = bS[17][bS[18]];
                        bS[20] = 0;
                        bS[19] = 0;
                        bS[18] = 1;
                        bS[21] = 30;
                        bS[17] = bS[16](bS[18], bS[19], bS[20], bS[21]);
                        bS[20] = 14269763344884;
                        bS[26] = 29842078103112;
                        bS[15][bS[13]] = bS[17];
                        bS[16] = r15;
                        bS[22] = "D\xde\x14";
                        bS[17] = r16;
                        bS[19] = "x\x9c\xee>%?\x99\xec";
                        bS[18] = bS[17](bS[19], bS[20]);
                        bS[23] = 9939308876308;
                        bS[13] = bS[16][bS[18]];
                        bS[18] = "UDim2";
                        bS[17] = Env[bS[18]];
                        bS[19] = r15;
                        bS[20] = r16;
                        bS[21] = bS[20](bS[22], bS[23]);
                        bS[18] = bS[19][bS[21]];
                        bS[16] = bS[17][bS[18]];
                        bS[18] = 0;
                        bS[21] = 0;
                        bS[20] = 0;
                        bS[19] = 0;
                        bS[17] = bS[16](bS[18], bS[19], bS[20], bS[21]);
                        bS[15][bS[13]] = bS[17];
                        bS[20] = 115116343349;
                        bS[16] = r15;
                        bS[17] = r16;
                        bS[19] = "k\xc0\xbd\xfb\x11\xeb\xf1\xf8X\xb2\x13{'p[|\xab\x1b.\xb3\xe7\x18";
                        bS[18] = bS[17](bS[19], bS[20]);
                        bS[13] = bS[16][bS[18]];
                        bS[16] = 1;
                        bS[15][bS[13]] = bS[16];
                        bS[19] = "\xe6\xb5\xe3}";
                        bS[16] = r15;
                        bS[20] = 4880078096608;
                        bS[17] = r16;
                        bS[23] = 29175423350033;
                        bS[21] = 12015705052635;
                        bS[18] = bS[17](bS[19], bS[20]);
                        bS[13] = bS[16][bS[18]];
                        bS[20] = "x\x93Nv\x8c\x11\t";
                        bS[17] = r15;
                        bS[18] = r16;
                        bS[19] = bS[18](bS[20], bS[21]);
                        bS[20] = 27854150562474;
                        bS[16] = bS[17][bS[19]];
                        bS[19] = "\xe0\xc1\x1b\x8c\x00h\x90\x9e\x08\x88";
                        bS[15][bS[13]] = bS[16];
                        bS[16] = r15;
                        bS[22] = "\x1fh\xc2\xc6\xc8\xba\xa1";
                        bS[17] = r16;
                        bS[18] = bS[17](bS[19], bS[20]);
                        bS[13] = bS[16][bS[18]];
                        bS[18] = "Color3";
                        bS[17] = Env[bS[18]];
                        bS[19] = r15;
                        bS[20] = r16;
                        bS[21] = bS[20](bS[22], bS[23]);
                        bS[18] = bS[19][bS[21]];
                        bS[16] = bS[17][bS[18]];
                        bS[18] = 230;
                        bS[19] = 200;
                        bS[20] = 255;
                        bS[23] = "\x08+\xd6\xbe";
                        bS[17] = bS[16](bS[18], bS[19], bS[20]);
                        bS[20] = 16159075065188;
                        bS[25] = 14601932724879;
                        bS[15][bS[13]] = bS[17];
                        bS[16] = r15;
                        bS[19] = "k\xbcI{4\xbf\t\x0f";
                        bS[17] = r16;
                        bS[18] = bS[17](bS[19], bS[20]);
                        bS[13] = bS[16][bS[18]];
                        bS[16] = 16;
                        bS[15][bS[13]] = bS[16];
                        bS[20] = 3791581808357;
                        bS[16] = r15;
                        bS[19] = "\x84\x95\xb5\xfc";
                        bS[17] = r16;
                        bS[18] = bS[17](bS[19], bS[20]);
                        bS[13] = bS[16][bS[18]];
                        bS[19] = "Enum";
                        bS[18] = Env[bS[19]];
                        bS[20] = r15;
                        bS[21] = r16;
                        bS[22] = bS[21](bS[23], bS[24]);
                        bS[19] = bS[20][bS[22]];
                        bS[17] = bS[18][bS[19]];
                        bS[22] = "\x7fP\x9d\xee+\xbc\x88:\xe1\x9a";
                        bS[23] = 2415139177572;
                        bS[19] = r15;
                        bS[20] = r16;
                        bS[21] = bS[20](bS[22], bS[23]);
                        bS[18] = bS[19][bS[21]];
                        bS[16] = bS[17][bS[18]];
                        bS[15][bS[13]] = bS[16];
                        bS[16] = r15;
                        bS[19] = "|R \x02\x17\xdc";
                        bS[21] = ")\xffR";
                        bS[20] = 34408164671126;
                        bS[17] = r16;
                        bS[18] = bS[17](bS[19], bS[20]);
                        bS[13] = bS[16][bS[18]];
                        bS[17] = "Instance";
                        bS[22] = 13905839167819;
                        bS[16] = bS[14];
                        bS[23] = "\xd9([";
                        bS[15][bS[13]] = bS[16];
                        bS[16] = Env[bS[17]];
                        bS[24] = 19050086130342;
                        bS[18] = r15;
                        bS[19] = r16;
                        bS[20] = bS[19](bS[21], bS[22]);
                        bS[17] = bS[18][bS[20]];
                        bS[13] = bS[16][bS[17]];
                        bS[21] = "D$=\xde\xa2@\xc9#\xd0";
                        bS[22] = 20600081048952;
                        bS[18] = r15;
                        bS[19] = r16;
                        bS[20] = bS[19](bS[21], bS[22]);
                        bS[22] = 4391735199741;
                        bS[17] = bS[18][bS[20]];
                        bS[16] = bS[13](bS[17]);
                        bS[17] = r15;
                        bS[21] = 11355296404647;
                        bS[18] = r16;
                        bS[20] = "\x0c\xe2\xe4\xfc";
                        bS[19] = bS[18](bS[20], bS[21]);
                        bS[13] = bS[17][bS[19]];
                        bS[18] = r15;
                        bS[21] = "\xb8\xfb\x91\xa0\xce\x8a\x06\xcb\xe9\xc6\x0c";
                        bS[19] = r16;
                        bS[20] = bS[19](bS[21], bS[22]);
                        bS[17] = bS[18][bS[20]];
                        bS[21] = 20615528031615;
                        bS[16][bS[13]] = bS[17];
                        bS[20] = "<\x11\xb8\xfc";
                        bS[17] = r15;
                        bS[18] = r16;
                        bS[19] = bS[18](bS[20], bS[21]);
                        bS[13] = bS[17][bS[19]];
                        bS[19] = "UDim2";
                        bS[18] = Env[bS[19]];
                        bS[20] = r15;
                        bS[21] = r16;
                        bS[22] = bS[21](bS[23], bS[24]);
                        bS[19] = bS[20][bS[22]];
                        bS[21] = 0;
                        bS[22] = 150;
                        bS[17] = bS[18][bS[19]];
                        bS[19] = 1;
                        bS[20] = -20;
                        bS[18] = bS[17](bS[19], bS[20], bS[21], bS[22]);
                        bS[20] = "\xf6\x18\xc8\x08.\x94\xfa\xd0";
                        bS[24] = 28250743321443;
                        bS[21] = 15715537263766;
                        bS[16][bS[13]] = bS[18];
                        bS[17] = r15;
                        bS[18] = r16;
                        bS[19] = bS[18](bS[20], bS[21]);
                        bS[13] = bS[17][bS[19]];
                        bS[19] = "UDim2";
                        bS[18] = Env[bS[19]];
                        bS[20] = r15;
                        bS[23] = "\x14D\xb3";
                        bS[21] = r16;
                        bS[22] = bS[21](bS[23], bS[24]);
                        bS[19] = bS[20][bS[22]];
                        bS[20] = 10;
                        bS[21] = 0;
                        bS[22] = 40;
                        bS[17] = bS[18][bS[19]];
                        bS[19] = 0;
                        bS[18] = bS[17](bS[19], bS[20], bS[21], bS[22]);
                        bS[23] = "/\xf7\x98h\xa9\x84\x16";
                        bS[21] = 25898236391195;
                        bS[16][bS[13]] = bS[18];
                        bS[17] = r15;
                        bS[20] = " \xdcJjk\xb2\xf3C\xe8F\x8fi<\x9dA\xc2\xfdf\xa6\xa7K\xf1";
                        bS[22] = 30928524113986;
                        bS[18] = r16;
                        bS[19] = bS[18](bS[20], bS[21]);
                        bS[13] = bS[17][bS[19]];
                        bS[17] = 1;
                        bS[16][bS[13]] = bS[17];
                        bS[17] = r15;
                        bS[20] = "\xdd\xa9H\xcc";
                        bS[21] = 12324676179563;
                        bS[18] = r16;
                        bS[19] = bS[18](bS[20], bS[21]);
                        bS[13] = bS[17][bS[19]];
                        bS[21] = "\xdd\xbf\x05\x7f\xc9\xee\xa5\xbc\xbf\x97\xb7\xaf\xf7;\xe2\x91Q\xf0\xd1\xc3\x84\xbd\xa4\xf0x\xb4\xeb\x82>aD=\xfc\xe1\x15\xedR\x91\xf0\xf7D\xeb[l&__\x9d\tzo\x81\xf5\x96!\xa3\xa2\xb0\xeb\xae\x93\xa448\x10X1\x02\x85\xa5C\x84\xde\x9e\xbddS\x85\x95\xa1\xe8gP3\xa3G;\xe4\x07s\x98\x96S\x1e\xf5\xbd\x92\x14\xbc`D\x18x\xc3\xd3\x8c\xd4\xfa6{\xa5\xdcp\x03\xd3\xd0\xab\xc9\x07$y\x02`\x14\x97\xa5\x08\x01t=g\x83\x14\xd66w\xf2h\x1c\x0e~c\x87r\xff\xcb[\xd9\xa5\xb5\xfe\x9a";
                        bS[18] = r15;
                        bS[19] = r16;
                        bS[20] = bS[19](bS[21], bS[22]);
                        bS[17] = bS[18][bS[20]];
                        bS[16][bS[13]] = bS[17];
                        bS[21] = 4597129365596;
                        bS[20] = "C\xe8$2\xe0\xa4(\xa1\xf0M";
                        bS[17] = r15;
                        bS[18] = r16;
                        bS[19] = bS[18](bS[20], bS[21]);
                        bS[13] = bS[17][bS[19]];
                        bS[19] = "Color3";
                        bS[24] = 11128707896382;
                        bS[18] = Env[bS[19]];
                        bS[20] = r15;
                        bS[21] = r16;
                        bS[33] = "\xa9\xc7\xde\x8c\xc5\tH";
                        bS[22] = bS[21](bS[23], bS[24]);
                        bS[21] = 220;
                        bS[19] = bS[20][bS[22]];
                        bS[17] = bS[18][bS[19]];
                        bS[19] = 200;
                        bS[20] = 180;
                        bS[18] = bS[17](bS[19], bS[20], bS[21]);
                        bS[16][bS[13]] = bS[18];
                        bS[17] = r15;
                        bS[18] = r16;
                        bS[20] = "\xdeq\xf8K\x90\xaa\x0c/";
                        bS[21] = 26022636564309;
                        bS[19] = bS[18](bS[20], bS[21]);
                        bS[20] = "\xc0#\xd5aLR\r$\xbb@\xa9";
                        bS[13] = bS[17][bS[19]];
                        bS[17] = 12;
                        bS[16][bS[13]] = bS[17];
                        bS[17] = r15;
                        bS[18] = r16;
                        bS[21] = 21216803481239;
                        bS[19] = bS[18](bS[20], bS[21]);
                        bS[13] = bS[17][bS[19]];
                        bS[17] = true;
                        bS[24] = "\x0cr\x9bo\x92\xaf\xc9\x9c\x1a\xa2\xb6\x15\x8d9";
                        bS[16][bS[13]] = bS[17];
                        bS[20] = "\nl\xb1\t/\xa5\xa5\x88\x97v\xca}\xaa\x04";
                        bS[21] = 22298277226639;
                        bS[17] = r15;
                        bS[18] = r16;
                        bS[19] = bS[18](bS[20], bS[21]);
                        bS[13] = bS[17][bS[19]];
                        bS[20] = "Enum";
                        bS[19] = Env[bS[20]];
                        bS[21] = r15;
                        bS[22] = r16;
                        bS[23] = bS[22](bS[24], bS[25]);
                        bS[20] = bS[21][bS[23]];
                        bS[18] = bS[19][bS[20]];
                        bS[35] = 31829088500197;
                        bS[25] = 28871696069764;
                        bS[20] = r15;
                        bS[21] = r16;
                        bS[23] = "u\x16\x19\x98";
                        bS[24] = 30745309575148;
                        bS[22] = bS[21](bS[23], bS[24]);
                        bS[19] = bS[20][bS[22]];
                        bS[17] = bS[18][bS[19]];
                        bS[24] = "\xe7u\xfe\xc1";
                        bS[16][bS[13]] = bS[17];
                        bS[17] = r15;
                        bS[21] = 33265601494146;
                        bS[20] = "nX\xcau";
                        bS[18] = r16;
                        bS[19] = bS[18](bS[20], bS[21]);
                        bS[13] = bS[17][bS[19]];
                        bS[20] = "Enum";
                        bS[19] = Env[bS[20]];
                        bS[21] = r15;
                        bS[22] = r16;
                        bS[23] = bS[22](bS[24], bS[25]);
                        bS[20] = bS[21][bS[23]];
                        bS[18] = bS[19][bS[20]];
                        bS[20] = r15;
                        bS[24] = 5500246346241;
                        bS[23] = "\xadA\xc1\xe9\x85\xb3";
                        bS[21] = r16;
                        bS[22] = bS[21](bS[23], bS[24]);
                        bS[23] = 33751774166372;
                        bS[19] = bS[20][bS[22]];
                        bS[17] = bS[18][bS[19]];
                        bS[16][bS[13]] = bS[17];
                        bS[21] = 33380717837496;
                        bS[17] = r15;
                        bS[22] = "\x98\xb5\xdb";
                        bS[20] = "\xb9\xc3\x1aE0n";
                        bS[18] = r16;
                        bS[19] = bS[18](bS[20], bS[21]);
                        bS[13] = bS[17][bS[19]];
                        bS[17] = bS[14];
                        bS[18] = "Instance";
                        bS[16][bS[13]] = bS[17];
                        bS[17] = Env[bS[18]];
                        bS[19] = r15;
                        bS[20] = r16;
                        bS[21] = bS[20](bS[22], bS[23]);
                        bS[25] = "\x18\x0c^";
                        bS[23] = 17515951415260;
                        bS[18] = bS[19][bS[21]];
                        bS[13] = bS[17][bS[18]];
                        bS[22] = "o\x9a\xa6\x95-\x8f;\xcd\x8d\xac";
                        bS[19] = r15;
                        bS[20] = r16;
                        bS[21] = bS[20](bS[22], bS[23]);
                        bS[18] = bS[19][bS[21]];
                        bS[22] = "\x03\xcd-\xa5";
                        bS[17] = bS[13](bS[18]);
                        bS[23] = 26050496294754;
                        bS[13] = 12;
                        o[bS[13]] = bS[17];
                        bS[17] = o[bS[13]];
                        bS[19] = r15;
                        bS[20] = r16;
                        bS[21] = bS[20](bS[22], bS[23]);
                        bS[24] = 27742825427574;
                        bS[23] = "\xca\xcau\xdd\xd3z\x83z\xd8d\"W\xfc";
                        bS[18] = bS[19][bS[21]];
                        bS[20] = r15;
                        bS[21] = r16;
                        bS[22] = bS[21](bS[23], bS[24]);
                        bS[23] = 33675026480449;
                        bS[19] = bS[20][bS[22]];
                        bS[17][bS[18]] = bS[19];
                        bS[17] = o[bS[13]];
                        bS[19] = r15;
                        bS[22] = "Ew\xf5\x02";
                        bS[20] = r16;
                        bS[21] = bS[20](bS[22], bS[23]);
                        bS[18] = bS[19][bS[21]];
                        bS[21] = "UDim2";
                        bS[20] = Env[bS[21]];
                        bS[22] = r15;
                        bS[23] = r16;
                        bS[24] = bS[23](bS[25], bS[26]);
                        bS[21] = bS[22][bS[24]];
                        bS[23] = 0;
                        bS[22] = 0;
                        bS[19] = bS[20][bS[21]];
                        bS[26] = 905793552805;
                        bS[21] = .85;
                        bS[24] = 42;
                        bS[20] = bS[19](bS[21], bS[22], bS[23], bS[24]);
                        bS[17][bS[18]] = bS[20];
                        bS[17] = o[bS[13]];
                        bS[19] = r15;
                        bS[20] = r16;
                        bS[23] = 104988344368;
                        bS[22] = "\xf9>^_\xbc\xef\xda\xe1";
                        bS[21] = bS[20](bS[22], bS[23]);
                        bS[18] = bS[19][bS[21]];
                        bS[21] = "UDim2";
                        bS[20] = Env[bS[21]];
                        bS[22] = r15;
                        bS[23] = r16;
                        bS[25] = "\xacJ\xb9";
                        bS[24] = bS[23](bS[25], bS[26]);
                        bS[21] = bS[22][bS[24]];
                        bS[23] = 0;
                        bS[22] = 0;
                        bS[25] = "\x0eT\xa1\xd8\x17\x92U";
                        bS[19] = bS[20][bS[21]];
                        bS[21] = .075;
                        bS[24] = 0;
                        bS[20] = bS[19](bS[21], bS[22], bS[23], bS[24]);
                        bS[30] = "\x94\x82\xbc";
                        bS[26] = 14010827512188;
                        bS[17][bS[18]] = bS[20];
                        bS[17] = o[bS[13]];
                        bS[23] = 29065870669022;
                        bS[22] = "\x8d`2\xb6\r\xa8\xda\xab2\xff\x17\xa6\x04[\n\xb5";
                        bS[19] = r15;
                        bS[20] = r16;
                        bS[21] = bS[20](bS[22], bS[23]);
                        bS[18] = bS[19][bS[21]];
                        bS[21] = "Color3";
                        bS[20] = Env[bS[21]];
                        bS[22] = r15;
                        bS[23] = r16;
                        bS[24] = bS[23](bS[25], bS[26]);
                        bS[21] = bS[22][bS[24]];
                        bS[23] = 80;
                        bS[22] = 80;
                        bS[25] = "\x942\xf3\x03b\xab\x04";
                        bS[19] = bS[20][bS[21]];
                        bS[21] = 180;
                        bS[20] = bS[19](bS[21], bS[22], bS[23]);
                        bS[17][bS[18]] = bS[20];
                        bS[22] = "\xf0\xfcIN@\xd9\xcffU \xd9\x13\x85I2cm)\xf9\xe3a\x95";
                        bS[17] = o[bS[13]];
                        bS[19] = r15;
                        bS[20] = r16;
                        bS[23] = 21505874601758;
                        bS[21] = bS[20](bS[22], bS[23]);
                        bS[18] = bS[19][bS[21]];
                        bS[22] = "\x1f\xfcQ\xc5";
                        bS[19] = .1;
                        bS[17][bS[18]] = bS[19];
                        bS[17] = o[bS[13]];
                        bS[24] = 18402562711929;
                        bS[23] = 5236794968454;
                        bS[19] = r15;
                        bS[20] = r16;
                        bS[21] = bS[20](bS[22], bS[23]);
                        bS[18] = bS[19][bS[21]];
                        bS[23] = "1q\xea\t\x1eX\xe4o\xcf-\xf0\xd8\xe0\xd1H=\xf7";
                        bS[20] = r15;
                        bS[21] = r16;
                        bS[22] = bS[21](bS[23], bS[24]);
                        bS[19] = bS[20][bS[22]];
                        bS[17][bS[18]] = bS[19];
                        bS[17] = o[bS[13]];
                        bS[23] = 6937030544542;
                        bS[22] = "\x9a\x8e\xae\xbf\xb4UE\x89\x1e\xe0";
                        bS[19] = r15;
                        bS[20] = r16;
                        bS[21] = bS[20](bS[22], bS[23]);
                        bS[18] = bS[19][bS[21]];
                        bS[21] = "Color3";
                        bS[20] = Env[bS[21]];
                        bS[22] = r15;
                        bS[26] = 24286881098797;
                        bS[23] = r16;
                        bS[24] = bS[23](bS[25], bS[26]);
                        bS[21] = bS[22][bS[24]];
                        bS[19] = bS[20][bS[21]];
                        bS[22] = 255;
                        bS[21] = 255;
                        bS[23] = 255;
                        bS[20] = bS[19](bS[21], bS[22], bS[23]);
                        bS[17][bS[18]] = bS[20];
                        bS[23] = 34118099992079;
                        bS[17] = o[bS[13]];
                        bS[19] = r15;
                        bS[22] = "\xb8V\x0f\xec\xed\x17\xfa\x06";
                        bS[20] = r16;
                        bS[21] = bS[20](bS[22], bS[23]);
                        bS[18] = bS[19][bS[21]];
                        bS[22] = "\xcf\xc3\xd3\xb5";
                        bS[19] = 14;
                        bS[26] = "\t\x19\xc7\x97";
                        bS[17][bS[18]] = bS[19];
                        bS[17] = o[bS[13]];
                        bS[19] = r15;
                        bS[23] = 3401760769;
                        bS[20] = r16;
                        bS[21] = bS[20](bS[22], bS[23]);
                        bS[22] = "Enum";
                        bS[18] = bS[19][bS[21]];
                        bS[21] = Env[bS[22]];
                        bS[23] = r15;
                        bS[24] = r16;
                        bS[25] = bS[24](bS[26], bS[27]);
                        bS[27] = "U6\x01";
                        bS[26] = 11258404066426;
                        bS[22] = bS[23][bS[25]];
                        bS[20] = bS[21][bS[22]];
                        bS[22] = r15;
                        bS[25] = "\xa6\t#\xb0\xa1\x88\xa2p~x";
                        bS[23] = r16;
                        bS[24] = bS[23](bS[25], bS[26]);
                        bS[21] = bS[22][bS[24]];
                        bS[26] = 9501017084232;
                        bS[22] = "\x856\x12-|~\xe5\xb1\x054\x9c";
                        bS[19] = bS[20][bS[21]];
                        bS[17][bS[18]] = bS[19];
                        bS[17] = o[bS[13]];
                        bS[19] = r15;
                        bS[23] = 30931925874755;
                        bS[20] = r16;
                        bS[21] = bS[20](bS[22], bS[23]);
                        bS[23] = 19597874766757;
                        bS[18] = bS[19][bS[21]];
                        bS[19] = 4;
                        bS[17][bS[18]] = bS[19];
                        bS[17] = o[bS[13]];
                        bS[19] = r15;
                        bS[22] = "\x03p<\xca\xa7\xe5";
                        bS[20] = r16;
                        bS[21] = bS[20](bS[22], bS[23]);
                        bS[18] = bS[19][bS[21]];
                        bS[19] = r144;
                        bS[17][bS[18]] = bS[19];
                        bS[19] = "Instance";
                        bS[23] = "\xbd\xfb\xf2";
                        bS[18] = Env[bS[19]];
                        bS[20] = r15;
                        bS[21] = r16;
                        bS[24] = 22387111962808;
                        bS[22] = bS[21](bS[23], bS[24]);
                        bS[25] = "\xf3\xccr";
                        bS[19] = bS[20][bS[22]];
                        bS[17] = bS[18][bS[19]];
                        bS[20] = r15;
                        bS[24] = 21770190333849;
                        bS[21] = r16;
                        bS[23] = "\xa2L?\x14f[\xe9|";
                        bS[22] = bS[21](bS[23], bS[24]);
                        bS[19] = bS[20][bS[22]];
                        bS[18] = bS[17](bS[19]);
                        bS[22] = "b\xa2q`$Zf\xba\xd1J\x06\x97";
                        bS[23] = 5630306159165;
                        bS[19] = r15;
                        bS[20] = r16;
                        bS[21] = bS[20](bS[22], bS[23]);
                        bS[17] = bS[19][bS[21]];
                        bS[21] = "UDim";
                        bS[20] = Env[bS[21]];
                        bS[22] = r15;
                        bS[23] = r16;
                        bS[24] = bS[23](bS[25], bS[26]);
                        bS[21] = bS[22][bS[24]];
                        bS[19] = bS[20][bS[21]];
                        bS[22] = 8;
                        bS[21] = 0;
                        bS[24] = "2\xf8(";
                        bS[20] = bS[19](bS[21], bS[22]);
                        bS[18][bS[17]] = bS[20];
                        bS[22] = "\x1e\xc1}\xa4\xf1W";
                        bS[23] = 1187750969897;
                        bS[19] = r15;
                        bS[20] = r16;
                        bS[21] = bS[20](bS[22], bS[23]);
                        bS[17] = bS[19][bS[21]];
                        bS[19] = o[bS[13]];
                        bS[25] = 1191243629098;
                        bS[18][bS[17]] = bS[19];
                        bS[20] = "Instance";
                        bS[19] = Env[bS[20]];
                        bS[21] = r15;
                        bS[22] = r16;
                        bS[23] = bS[22](bS[24], bS[25]);
                        bS[20] = bS[21][bS[23]];
                        bS[17] = bS[19][bS[20]];
                        bS[21] = r15;
                        bS[22] = r16;
                        bS[24] = "IB\xcbw\x83F5\xbf\x1d\x14";
                        bS[25] = 7582246473162;
                        bS[23] = bS[22](bS[24], bS[25]);
                        bS[20] = bS[21][bS[23]];
                        bS[19] = bS[17](bS[20]);
                        bS[17] = 13;
                        o[bS[17]] = bS[19];
                        bS[19] = o[bS[17]];
                        bS[21] = r15;
                        bS[22] = r16;
                        bS[24] = "h\x89\xe1\xde\xa0";
                        bS[25] = 30059447039661;
                        bS[23] = bS[22](bS[24], bS[25]);
                        bS[20] = bS[21][bS[23]];
                        bS[23] = "ColorSequence";
                        bS[22] = Env[bS[23]];
                        bS[24] = r15;
                        bS[25] = r16;
                        bS[26] = bS[25](bS[27], bS[28]);
                        bS[23] = bS[24][bS[26]];
                        bS[26] = "ColorSequenceKeypoint";
                        bS[21] = bS[22][bS[23]];
                        bS[25] = Env[bS[26]];
                        bS[27] = r15;
                        bS[28] = r16;
                        bS[29] = bS[28](bS[30], bS[31]);
                        bS[26] = bS[27][bS[29]];
                        bS[29] = "Color3";
                        bS[24] = bS[25][bS[26]];
                        bS[28] = Env[bS[29]];
                        bS[30] = r15;
                        bS[31] = r16;
                        bS[32] = bS[31](bS[33], bS[34]);
                        bS[26] = 0;
                        bS[29] = bS[30][bS[32]];
                        bS[30] = 100;
                        bS[34] = "it\x0e!\xf0D\x13";
                        bS[27] = bS[28][bS[29]];
                        bS[31] = 100;
                        bS[29] = 200;
                        bS[28] = {
                            bS[27](bS[29], bS[30], bS[31])
                        };
                        bS[27] = "ColorSequenceKeypoint";
                        bS[25] = bS[24](bS[26], x(bS[28]));
                        bS[32] = 24207441406984;
                        bS[26] = Env[bS[27]];
                        bS[28] = r15;
                        bS[31] = "j\xeen";
                        bS[29] = r16;
                        bS[30] = bS[29](bS[31], bS[32]);
                        bS[27] = bS[28][bS[30]];
                        bS[24] = bS[26][bS[27]];
                        bS[30] = "Color3";
                        bS[27] = 0.5;
                        bS[29] = Env[bS[30]];
                        bS[31] = r15;
                        bS[32] = r16;
                        bS[33] = bS[32](bS[34], bS[35]);
                        bS[30] = bS[31][bS[33]];
                        bS[28] = bS[29][bS[30]];
                        bS[33] = 21185302439561;
                        bS[30] = 220;
                        bS[32] = 120;
                        bS[31] = 120;
                        bS[29] = {
                            bS[28](bS[30], bS[31], bS[32])
                        };
                        bS[28] = "ColorSequenceKeypoint";
                        bS[26] = bS[24](bS[27], x(bS[29]));
                        bS[27] = Env[bS[28]];
                        bS[29] = r15;
                        bS[32] = "G.\xca";
                        bS[30] = r16;
                        bS[31] = bS[30](bS[32], bS[33]);
                        bS[28] = bS[29][bS[31]];
                        bS[24] = bS[27][bS[28]];
                        bS[28] = 1;
                        bS[35] = "\xdeG\x1f\xfe\xba&*";
                        bS[31] = "Color3";
                        bS[30] = Env[bS[31]];
                        bS[32] = r15;
                        bS[33] = r16;
                        bS[34] = bS[33](bS[35], bS[36]);
                        bS[31] = bS[32][bS[34]];
                        bS[33] = 100;
                        bS[32] = 100;
                        bS[29] = bS[30][bS[31]];
                        bS[31] = 200;
                        bS[30] = {
                            bS[29](bS[31], bS[32], bS[33])
                        };
                        bS[27] = {
                            bS[24](bS[28], x(bS[30]))
                        };
                        bS[23] = {
                            bS[25],
                            bS[26],
                            x(bS[27])
                        };
                        bS[22] = bS[21](bS[23]);
                        bS[25] = 26486794514477;
                        bS[24] = "'Pt\"?\x97\x1a}";
                        bS[19][bS[20]] = bS[22];
                        bS[26] = 23603889335023;
                        bS[19] = o[bS[17]];
                        bS[21] = r15;
                        bS[22] = r16;
                        bS[23] = bS[22](bS[24], bS[25]);
                        bS[20] = bS[21][bS[23]];
                        bS[25] = 21290290783930;
                        bS[21] = 90;
                        bS[19][bS[20]] = bS[21];
                        bS[24] = "\x12^\xc9\xcaS\xf7";
                        bS[19] = o[bS[17]];
                        bS[21] = r15;
                        bS[22] = r16;
                        bS[23] = bS[22](bS[24], bS[25]);
                        bS[20] = bS[21][bS[23]];
                        bS[21] = o[bS[13]];
                        bS[25] = "Ago";
                        bS[19][bS[20]] = bS[21];
                        bS[21] = "Instance";
                        bS[20] = Env[bS[21]];
                        bS[22] = r15;
                        bS[23] = r16;
                        bS[24] = bS[23](bS[25], bS[26]);
                        bS[21] = bS[22][bS[24]];
                        bS[19] = bS[20][bS[21]];
                        bS[25] = "U\x85z4O\xb0\x18\x8e\xc5\n";
                        bS[26] = 20368293078284;
                        bS[22] = r15;
                        bS[23] = r16;
                        bS[24] = bS[23](bS[25], bS[26]);
                        bS[21] = bS[22][bS[24]];
                        bS[28] = "\xed\x9d\x1b";
                        bS[20] = bS[19](bS[21]);
                        bS[19] = 14;
                        o[bS[19]] = bS[20];
                        bS[25] = "\x89\xe3\x05\x11";
                        bS[20] = o[bS[19]];
                        bS[22] = r15;
                        bS[23] = r16;
                        bS[26] = 116746207286;
                        bS[24] = bS[23](bS[25], bS[26]);
                        bS[29] = 9925391831565;
                        bS[21] = bS[22][bS[24]];
                        bS[24] = "UDim2";
                        bS[23] = Env[bS[24]];
                        bS[25] = r15;
                        bS[26] = r16;
                        bS[27] = bS[26](bS[28], bS[29]);
                        bS[24] = bS[25][bS[27]];
                        bS[25] = 15;
                        bS[22] = bS[23][bS[24]];
                        bS[27] = 15;
                        bS[26] = 1;
                        bS[24] = 1;
                        bS[23] = bS[22](bS[24], bS[25], bS[26], bS[27]);
                        bS[20][bS[21]] = bS[23];
                        bS[29] = 18519308919215;
                        bS[25] = "\xa1(\x1aV\xca*\x19s";
                        bS[20] = o[bS[19]];
                        bS[22] = r15;
                        bS[28] = "m\xba=";
                        bS[23] = r16;
                        bS[26] = 25605088063123;
                        bS[24] = bS[23](bS[25], bS[26]);
                        bS[21] = bS[22][bS[24]];
                        bS[24] = "UDim2";
                        bS[23] = Env[bS[24]];
                        bS[25] = r15;
                        bS[26] = r16;
                        bS[27] = bS[26](bS[28], bS[29]);
                        bS[26] = 0;
                        bS[24] = bS[25][bS[27]];
                        bS[27] = -7.5;
                        bS[25] = -7.5;
                        bS[22] = bS[23][bS[24]];
                        bS[24] = 0;
                        bS[23] = bS[22](bS[24], bS[25], bS[26], bS[27]);
                        bS[20][bS[21]] = bS[23];
                        bS[26] = 16862422376108;
                        bS[28] = "\xbbI\xcf\x91\x16\x99\xe3";
                        bS[30] = 14121845135791;
                        bS[25] = "\xd2\x8e\"\xc3G\xde?D\xe4r\xe1\x1b\xda\xc9\n\x92\xf1\xc7}\\\xa2*";
                        bS[20] = o[bS[19]];
                        bS[22] = r15;
                        bS[23] = r16;
                        bS[24] = bS[23](bS[25], bS[26]);
                        bS[21] = bS[22][bS[24]];
                        bS[22] = 1;
                        bS[20][bS[21]] = bS[22];
                        bS[20] = o[bS[19]];
                        bS[25] = "%\x8c\x95\xb6$";
                        bS[22] = r15;
                        bS[23] = r16;
                        bS[26] = 14707597056704;
                        bS[24] = bS[23](bS[25], bS[26]);
                        bS[27] = 17453036806079;
                        bS[26] = "d\x1a!\xcf\xa3%\x15\x07\xcd\xe4\xfc\xad@\x93\tm\xca\xbdFT\x03\xb0\x8a";
                        bS[21] = bS[22][bS[24]];
                        bS[23] = r15;
                        bS[24] = r16;
                        bS[25] = bS[24](bS[26], bS[27]);
                        bS[22] = bS[23][bS[25]];
                        bS[20][bS[21]] = bS[22];
                        bS[20] = o[bS[19]];
                        bS[22] = r15;
                        bS[26] = 16865824153261;
                        bS[25] = "A\x88\xeb|P\xa3\xd05\x93\x1aJ";
                        bS[23] = r16;
                        bS[24] = bS[23](bS[25], bS[26]);
                        bS[21] = bS[22][bS[24]];
                        bS[24] = "Color3";
                        bS[23] = Env[bS[24]];
                        bS[29] = 29708342457866;
                        bS[25] = r15;
                        bS[26] = r16;
                        bS[27] = bS[26](bS[28], bS[29]);
                        bS[26] = 130;
                        bS[24] = bS[25][bS[27]];
                        bS[25] = 130;
                        bS[22] = bS[23][bS[24]];
                        bS[24] = 220;
                        bS[23] = bS[22](bS[24], bS[25], bS[26]);
                        bS[25] = "\xc1\xd8\xcc\xb5p\xd7\x9b\xc5\x90\x1d@\xcbXt\xb6\x0b\x97";
                        bS[26] = 28711440872505;
                        bS[20][bS[21]] = bS[23];
                        bS[20] = o[bS[19]];
                        bS[22] = r15;
                        bS[23] = r16;
                        bS[24] = bS[23](bS[25], bS[26]);
                        bS[21] = bS[22][bS[24]];
                        bS[22] = .7;
                        bS[20][bS[21]] = bS[22];
                        bS[20] = o[bS[19]];
                        bS[26] = 12613377922801;
                        bS[22] = r15;
                        bS[29] = "\xc1\"\x89rM\xd2\xde\xfe\x17";
                        bS[25] = "\xf8\xe9\x9f\xaf%\xb0\xfe\x9a\xcd";
                        bS[23] = r16;
                        bS[24] = bS[23](bS[25], bS[26]);
                        bS[25] = "Enum";
                        bS[21] = bS[22][bS[24]];
                        bS[24] = Env[bS[25]];
                        bS[26] = r15;
                        bS[27] = r16;
                        bS[28] = bS[27](bS[29], bS[30]);
                        bS[29] = 15914180746482;
                        bS[25] = bS[26][bS[28]];
                        bS[23] = bS[24][bS[25]];
                        bS[25] = r15;
                        bS[26] = r16;
                        bS[28] = "\x14\xb7\xc0I~";
                        bS[27] = bS[26](bS[28], bS[29]);
                        bS[26] = 34383568273035;
                        bS[24] = bS[25][bS[27]];
                        bS[22] = bS[23][bS[24]];
                        bS[25] = "@\xed\xa8\xdb\xeajr\xd2\x81\x93\xcc";
                        bS[20][bS[21]] = bS[22];
                        bS[20] = o[bS[19]];
                        bS[22] = r15;
                        bS[23] = r16;
                        bS[28] = "\xb8\xf0\x1c";
                        bS[24] = bS[23](bS[25], bS[26]);
                        bS[21] = bS[22][bS[24]];
                        bS[24] = "Rect";
                        bS[23] = Env[bS[24]];
                        bS[29] = 19752151294957;
                        bS[25] = r15;
                        bS[26] = r16;
                        bS[27] = bS[26](bS[28], bS[29]);
                        bS[26] = 276;
                        bS[24] = bS[25][bS[27]];
                        bS[25] = 24;
                        bS[27] = 276;
                        bS[22] = bS[23][bS[24]];
                        bS[24] = 24;
                        bS[23] = bS[22](bS[24], bS[25], bS[26], bS[27]);
                        bS[20][bS[21]] = bS[23];
                        bS[26] = 25415197830714;
                        bS[20] = o[bS[19]];
                        bS[22] = r15;
                        bS[23] = r16;
                        bS[25] = "j\x16\x17Ga\x03";
                        bS[24] = bS[23](bS[25], bS[26]);
                        bS[21] = bS[22][bS[24]];
                        bS[22] = -1;
                        bS[27] = 20943394924056;
                        bS[26] = 386947137716;
                        bS[20][bS[21]] = bS[22];
                        bS[20] = o[bS[19]];
                        bS[22] = r15;
                        bS[23] = r16;
                        bS[25] = "\x1a\xad7\xa4\x912";
                        bS[24] = bS[23](bS[25], bS[26]);
                        bS[21] = bS[22][bS[24]];
                        bS[22] = o[bS[13]];
                        bS[20][bS[21]] = bS[22];
                        bS[26] = "_\xfb\xa9q\xa7\x8f\xa8%Kl";
                        bS[21] = o[bS[13]];
                        bS[23] = r15;
                        bS[24] = r16;
                        bS[25] = bS[24](bS[26], bS[27]);
                        bS[22] = bS[23][bS[25]];
                        bS[20] = bS[21][bS[22]];
                        bS[22] = function(...)
                            v8 = r27;
                            v3 = v8.Create(v8, o[bS[13]], TweenInfo.new(.2), {
                                ["BackgroundTransparency"] = .05,
                                ["Size"] = UDim2.new(.86, 0, 0, 44)
                            });
                            v3.Play(v3);
                            v8 = r27;
                            v3 = v8.Create(v8, o[bS[17]], TweenInfo.new(.2), {
                                ["Rotation"] = 270
                            });
                            v3.Play(v3);
                            v8 = r27;
                            v3 = v8.Create(v8, o[bS[19]], TweenInfo.new(.2), {
                                ["ImageTransparency"] = 0.5
                            });
                            v3.Play(v3);
                            return; 
                        end;
                        bS[21] = "Connect";
                        bS[21] = bS[20][bS[21]];
                        bS[27] = 4171677894550;
                        bS[21] = bS[21](bS[20], bS[22]);
                        bS[21] = o[bS[13]];
                        bS[26] = "2\xdfv\xc0z\x89A\x10\x84\x8a";
                        bS[23] = r15;
                        bS[24] = r16;
                        bS[25] = bS[24](bS[26], bS[27]);
                        bS[22] = bS[23][bS[25]];
                        bS[20] = bS[21][bS[22]];
                        bS[22] = function(...)
                            v8 = r27;
                            v3 = v8.Create(v8, o[bS[13]], TweenInfo.new(.2), {
                                ["BackgroundTransparency"] = .1,
                                ["Size"] = UDim2.new(.85, 0, 0, 42)
                            });
                            v3.Play(v3);
                            v8 = r27;
                            v3 = v8.Create(v8, o[bS[17]], TweenInfo.new(.2), {
                                ["Rotation"] = 90
                            });
                            v3.Play(v3);
                            v8 = r27;
                            v3 = v8.Create(v8, o[bS[19]], TweenInfo.new(.2), {
                                ["ImageTransparency"] = .7
                            });
                            v3.Play(v3);
                            return; 
                        end;
                        bS[21] = "Connect";
                        bS[21] = bS[20][bS[21]];
                        bS[27] = 19379009348416;
                        bS[26] = "\x92\xc6i\x14\xa9\x97(w\xe6\xc7\x916u1%\x0b\xdc";
                        bS[21] = bS[21](bS[20], bS[22]);
                        bS[21] = o[bS[13]];
                        bS[23] = r15;
                        bS[24] = r16;
                        bS[25] = bS[24](bS[26], bS[27]);
                        bS[22] = bS[23][bS[25]];
                        bS[20] = bS[21][bS[22]];
                        bS[21] = "Connect";
                        bS[26] = "2\x80M\x97\r\xcc\xfaTo\x84\x90\xa1)\xc6\x90~\xd9\x049";
                        bS[27] = 31645632739728;
                        bS[22] = function(...)
                            r43 = table.clone(r42);
                            r33 = 1;
                            r34 = 1;
                            r35 = 1;
                            r36 = 1;
                            v7 = o[bS[3]];
                            P = c[1];
                            v4 = c[2];
                            for v2, v7 in ipairs(v7) do
                                q = v2;
                                c = r173;
                                K = c.FindFirstChild(c, v7.key .. "Container");
                                if K then
                                    v9 = r16;
                                    c = K.FindFirstChild(K, "KeybindButton");
                                    if c then
                                        v9 = tostring(r43[v7.key]);
                                        c.Text = v9.gsub(v9, "Enum.KeyCode.", "");
                                    end;
                                end; 
                            end;
                            c = "name";
                            K = "Boost3";
                            v2 = c[2];
                            v4 = c[1];
                            for v7, c in ipairs({
                                {
                                    ["name"] = "BaseSpeed",
                                    ["value"] = r33
                                },
                                {
                                    ["name"] = "Boost1",
                                    ["value"] = r34
                                },
                                {
                                    ["name"] = "Boost2",
                                    ["value"] = r35
                                },
                                {
                                    [c] = K,
                                    ["value"] = r36
                                }
                            }) do
                                K = o[bS[9]];
                                P = v7;
                                if K.FindFirstChild(K, c.name .. "Container") then
                                    K = v6.FindFirstChild(v6, "TextInputContainer");
                                    if K then
                                        r = K.FindFirstChild(K, "TextInput");
                                        if r then
                                            r.Text = string.format("%.2f", c.value);
                                        end;
                                    end;
                                    r = v6.FindFirstChild(v6, "ValueDisplay");
                                    if r then
                                        r.Text = "x" .. string.format("%.2f", c.value);
                                    end;
                                    v9 = v6.FindFirstChild(v6, "SliderContainer");
                                    if v9 then
                                        v10 = v9.FindFirstChild(v9, "SliderTrack");
                                        if v10 then
                                            G = r16;
                                            t = v10.FindFirstChild(v10, "SliderFill");
                                            if t then
                                                F = r27;
                                                G = F.Create(F, t, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                                                    ["Size"] = UDim2.new(math.min(c.value / 10, 1), 0, 1, 0)
                                                });
                                                G.Play(G);
                                            end;
                                        end;
                                    end;
                                end; 
                            end;
                            o[bS[20]]();
                            r86();
                            o[bS[5]]("Settings reset to defaults!", false, 2);
                            return; 
                        end;
                        bS[21] = bS[20][bS[21]];
                        bS[21] = bS[21](bS[20], bS[22]);
                        bS[20] = r172;
                        bS[23] = r15;
                        bS[24] = r16;
                        bS[21] = "GetPropertyChangedSignal";
                        bS[21] = bS[20][bS[21]];
                        bS[25] = bS[24](bS[26], bS[27]);
                        bS[22] = bS[23][bS[25]];
                        bS[21] = bS[21](bS[20], bS[22]);
                        bS[22] = function(...)
                            r144.CanvasSize = UDim2.new(0, 0, 0, r172.AbsoluteContentSize.Y + 20);
                            return; 
                        end;
                        bS[20] = "Connect";
                        bS[20] = bS[21][bS[20]];
                        bS[20] = bS[20](bS[21], bS[22]);
                        return Instance.new("ScreenGui"), function(...)
                            r104 = not r104;
                            if r104 then
                                o[xS].Visible = true;
                                v3 = r27;
                                v1 = v3.Create(v3, o[xS], TweenInfo.new(.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                                    ["Position"] = UDim2.new(1, -70, 0.5, 0)
                                });
                                v1.Play(v1);
                                v3 = r27;
                                v1 = v3.Create(v3, r107, TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                                    ["ImageColor3"] = Color3.fromRGB(200, 150, 255)
                                });
                                v1.Play(v1);
                                o[HS]();
                            else
                                v3 = r27;
                                v1 = v3.Create(v3, o[xS], TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                                    ["Position"] = UDim2.new(1, 400, 0.5, 0)
                                });
                                v1.Play(v1);
                                v3 = r27;
                                v1 = v3.Create(v3, r107, TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                                    ["ImageColor3"] = Color3.fromRGB(240, 200, 255)
                                });
                                v1.Play(v1);
                                task.wait(0.5);
                                if not r104 then
                                    o[xS].Visible = false;
                                end;
                                return;
                            end; 
                        end;
                    else
                        bS[20] = 17594993156097;
                        bS[15] = "UDim2";
                        bS[19] = "\x0b\t\xce";
                        bS[14] = Env[bS[15]];
                        bS[16] = r15;
                        bS[17] = r16;
                        bS[18] = bS[17](bS[19], bS[20]);
                        bS[17] = 0;
                        bS[15] = bS[16][bS[18]];
                        bS[13] = bS[14][bS[15]];
                        bS[18] = 2;
                        bS[16] = 2;
                        bS[15] = 0;
                        bS[14] = bS[13](bS[15], bS[16], bS[17], bS[18]);
                        bS[11] = bS[14];
                    end;
                else
                    bS[13] = "Color3";
                    bS[17] = "\xd2\xbc\xac\x0e\xf3\xaa\xec";
                    bS[12] = Env[bS[13]];
                    bS[14] = r15;
                    bS[15] = r16;
                    bS[18] = 1421293634197;
                    bS[16] = bS[15](bS[17], bS[18]);
                    bS[13] = bS[14][bS[16]];
                    bS[14] = 100;
                    bS[11] = bS[12][bS[13]];
                    bS[13] = 100;
                    bS[15] = 100;
                    bS[12] = bS[11](bS[13], bS[14], bS[15]);
                    bS[9] = bS[12];
                end;
            else
                Color3.fromRGB(255, 120, 120);
            end; 
        end;
        o[bS[24]] = bS[25];
        bS[7] = nil;
        bS[25] = function(...)
            v8 = game;
            v8 = game;
            r186 = v8.GetService(v8, "Players").LocalPlayer;
            v8 = v8.GetService(v8, "RunService").RenderStepped;
            v8.Connect(v8, function(...)
                if not r37 then
                    return;
                end;
                v1 = r186.Character;
                if not v1 then
                    return;
                end;
                P = "LeftLowerArm";
                v7 = "RightUpperArm";
                N = P[2];
                P = P[1];
                for q, v2 in ipairs({
                    "Left Arm",
                    "Right Arm",
                    "LeftHand",
                    "RightHand",
                    P,
                    "RightLowerArm",
                    "LeftUpperArm",
                    v7
                }) do
                    v4 = q;
                    v7 = v1.FindFirstChild(v1, v2);
                    if v7 then
                        v7.LocalTransparencyModifier = 0;
                        v9 = v7.GetChildren;
                        v6 = v9[3];
                        for v6, v9 in v9[1], ipairs(v9(v7)) do
                            r = v6;
                            if v9.IsA(v9, "Decal") or v9.IsA(v9, "Texture") then
                                v9.Transparency = 0;
                            else
                                if v9.IsA(v9, "MeshPart") then
                                    v9.LocalTransparencyModifier = 0;
                                end;
                            end; 
                        end;
                    end; 
                end;
                return; 
            end);
            return; 
        end;
        bS[18] = nil;
        bS[26] = bS[25]();
        bS[21] = nil;
        bS[14] = nil;
        bS[5] = nil;
        bS[6] = nil;
        bS[23] = nil;
        bS[19] = nil;
        bS[16] = nil;
        bS[9] = nil;
        bS[10] = nil;
        bS[22] = nil;
        bS[1] = nil;
        bS[15] = nil;
        bS[11] = nil;
        bS[25] = nil;
        bS[12] = nil;
        bS[20] = nil;
        bS[26] = 132;
        o[bS[26]] = bS[27];
        bS[27] = function(...)
            o[bS[4]]();
            r84();
            S = o[bS[24]]();
            o[bS[3]] = S[2];
            v3 = r29.CharacterAdded;
            v3.Connect(v3, function(arg1_42, ...)
                v1 = arg1_42;
                task.wait(.2);
                o[bS[26]]();
                return; 
            end);
            if r29.Character then
                o[bS[26]]();
            end;
            return; 
        end;
        bS[8] = nil;
        bS[3] = nil;
        bS[17] = nil;
        bS[24] = nil;
        bS[4] = nil;
        bS[2] = nil;
        bS[28] = bS[27]();
        bS[13] = nil;
        bS[26] = nil;
        bS[27] = nil;
        return;
    end;
end;
return (function(...)
    while true do
        l1 = l2;
        l2 = l1;
        r3(); 
    end;
    return; 
end)();
