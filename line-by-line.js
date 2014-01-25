/*
 * 逐行读取文件
 * 分段读取文件
 */
var fs = require('fs');
//每段读取的长度
//@param inputFile{filepath}
//@param onEnd{func} 所有内容读完了
module.exports = function(inputFile, onEnd){
    var sLength = 1024;
    var buffer = new Buffer(sLength);
    var _lineFragment = '';
    var fd = fs.openSync(inputFile, 'r');

    var position = 0;
    var i = 0;  //条数，从0开始计

    var block_queue = [];
    var block_fetching = false;

    var fetchBlock = function (callback){
        if(!callback){
            console.warn('no callback when call fetchBlock()')
        };

        if(!block_fetching){
            block_fetching = true;
        }else{
            block_queue.push(callback);
            return;
        }

        console.log('read postion: ', position);

        fs.read(fd, buffer, 0, sLength, position, function(err, bytesRead, buf){
            if(err) throw err;

            if(bytesRead === 0){
                onEnd(0, i);  //总数
                return;
            }
            //fs.read position会自己漂移？？
            position += bytesRead;
            //因为fs.read异步，顺序多次调用fetchBlock会导致读取同一position的块

            //regex from https://github.com/RustyMarvin/line-by-line/blob/master/line-by-line.js
            var lines = buf.toString('utf8', 0, bytesRead).split(/(?:\n|\r\n|\r)/g);

            lines[0] = _lineFragment + lines[0];
            _lineFragment = lines.pop() || '';

            block_fetching = false;
            if(callback){
                try{
                    callback(lines, i);
                }catch(e){
                    throw e;
                }
                i += lines.length;

                if(block_queue.length){
                    fetchBlock( block_queue.shift() );
                }
                return;
            }
        });
    };

    return fetchBlock;
};