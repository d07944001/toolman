pragma solidity >=0.5.0 <0.6.0;

contract Mating {
    struct GiveScore {
        address to;
        uint score;
    }

    struct ToolMan {
        uint toolCoin;
        uint serviceCoin;
        uint gender;
        uint datingPrice;
        uint[] servicePrice;
        string[] serviceContent;
        string[] selfIntro;
        uint[] receivedDatingScore;
        uint[] receivedServiceScore;
        uint[] giveDaingScore;
        uint[] giveServiceScore;
        uint servicekind;
        uint selfIntroVersion;
        uint washingIndex;
        string phoneNumber;
        string secret;
        string id;
    }

    uint contractAsset;
    uint contractServiceCoin;
    uint friendFee;
    uint maxScore;

    address payable contractOwner;
    address[] addressbook;
    address[] public washingAddress;

    mapping(address => ToolMan) toolman;
    mapping(address => bool) public isRegister;
    mapping(uint => uint) genderBonus;
    mapping(address => mapping(address => uint) ) friendRequest; // friendRequest[a][b]= a喜歡b而給b的錢
    mapping(address => mapping(address => bool) ) friends;  //friends[a][b]=true b把a當朋友
    mapping(address => mapping(address => bool) ) bedating; //a被b約
    mapping(address => mapping(address => bool) ) public beaskserving;   //   beaskserving[A][B]=true A服務B事件成交
    mapping(address => mapping(address => bool) ) callingService; // callingService[A][B]=true A服務B事件被call
    mapping(address => mapping(address => uint) ) numberService;
    mapping(address => mapping(address => bool) ) callingDating; //a被b約
    mapping(address => mapping(address => uint) ) antiWashingCoin; //反洗錢

    event Registered(address indexed user);
    event getserviceoffer(address indexed toolman, string serviceContent, uint price);
    
    event getupdateIntro(address indexed toolman, string selfIntro, uint datingPrice);
    
    event cancellServiceOffer(address indexed toolman, string serviceContent, uint price);
    event callService(address indexed lazyman, address indexed toolman, uint servicenumber);
    event serviceAccepted(address indexed toolman, address indexed lazyman);
    event callDating(address indexed toolman);
    event datingAccepted(address indexed lazyman, address indexed toolman);
    event finishService(address indexed lazyman, address indexed toolman, string serviceContent, uint price, uint score);
    event finishDating (address indexed toolman, address indexed lazyman, uint price, uint score);

    constructor() public payable {
        contractOwner = msg.sender;
        contractAsset = msg.value;
        contractServiceCoin = msg.value;
        genderBonus[0] = 10000;
        friendFee = 10;
        maxScore = 10;
    }
    
    //contract owner區##########################################################################
    function centerRegister(address newaccount, uint datingPrice, uint gender, string memory id) public payable{
        string memory non;
        non='';
        require(msg.sender==contractOwner); //須注意是否要比Hash值
        require(keccak256(abi.encodePacked(id)) != keccak256(abi.encodePacked(non)));
        require(!isRegister[newaccount]);
        require(genderBonus[gender] <= contractServiceCoin);
        ToolMan storage tool = toolman[newaccount];
        tool.datingPrice = datingPrice;
        tool.gender = gender;
        tool.id = id;
        tool.serviceCoin += genderBonus[gender] + msg.value;
        contractServiceCoin -= genderBonus[gender];
        contractAsset += msg.value;
        isRegister[newaccount] = true;
        addressbook.push(newaccount);
        //players += 1;
        emit Registered(newaccount);
    }
    
    function adjustContract(uint _friendFee, uint _maxScore) public {
        require(msg.sender == contractOwner);
        friendFee = _friendFee;
        maxScore = _maxScore;
    }

    function adjustGenderBonus(uint genderId, uint bonus) public {
        require(msg.sender == contractOwner);
        genderBonus[genderId] = bonus;
    }

    function ownerTransfer(uint amount, address luckyman) public payable {
        require(isRegister[msg.sender]);
        require(msg.sender == contractOwner);
        require(amount <= contractServiceCoin);
        ToolMan storage tool = toolman[luckyman];
        tool.serviceCoin += amount;
        contractServiceCoin -= amount;
    }
    
    //function ownerWithdraw(uint amount) public payable {
    //     require(amount <= contractAsset);
    //     contractOwner.transfer(amount);
    //     contractServiceCoin -= amount;
    //     contractAsset -= amount;
    // }
    //contract owner區##########################################################################
    
    //運作區####################################################################################
    function register(uint datingPrice, uint gender, string memory id) public payable{
        string memory non;
        non='';
        require(keccak256(abi.encodePacked(id)) != keccak256(abi.encodePacked(non)));
        require(!isRegister[msg.sender]);
        require(genderBonus[gender] <= contractServiceCoin);
        ToolMan storage tool = toolman[msg.sender];
        tool.datingPrice = datingPrice;
        tool.gender = gender;
        tool.id = id;
        tool.serviceCoin += genderBonus[gender] + msg.value;
        contractServiceCoin -= genderBonus[gender];
        contractAsset += msg.value;
        isRegister[msg.sender] = true;
       addressbook.push(msg.sender);
        //players += 1;
        if (gender==1){
            tool.toolCoin += genderBonus[0]; //內測優惠，男生一註冊就有工具人幣
        }
        emit Registered(msg.sender);
    }// 若要中心化控管使用者資格，用contract owner區function
    
    function callSpecificService (address toolper, uint number) public{
        //require(toolper != msg.sender);
        require(keccak256(abi.encodePacked(toolper)) != keccak256(abi.encodePacked(msg.sender)));
        require(callingService[toolper][msg.sender] == false);
        ToolMan storage tool = toolman[toolper];
        ToolMan storage lazy = toolman[msg.sender];
        uint price;
        price = tool.servicePrice[number];
        require(lazy.serviceCoin > price);        
        lazy.serviceCoin -= price;
        callingService[toolper][msg.sender] = true; 
        numberService[toolper][msg.sender] = number+1;
        emit callService (msg.sender, toolper, number);
    }
    
    function rejectService (address lazyman, uint number) public{
        require(callingService[msg.sender][lazyman] == true);
        callingService[msg.sender][lazyman] = false;
        ToolMan storage lazy = toolman[lazyman];
        ToolMan storage tool = toolman[msg.sender];
        lazy.serviceCoin +=  tool.servicePrice[number];
        numberService[msg.sender][lazyman] = 0;
    }
    
    function cancellCall (address toolper, uint number) public{
        require(callingService[toolper][msg.sender] == true);
        callingService[toolper][msg.sender] = false;
        ToolMan storage lazy = toolman[msg.sender];
        ToolMan storage tool = toolman[toolper];
        lazy.serviceCoin +=  tool.servicePrice[number];
        numberService[toolper][msg.sender] = 0;
    }
    
    function withdrawToolCoin(uint amount) public payable {
        require(isRegister[msg.sender]);
        ToolMan storage me = toolman[msg.sender];
        require(amount <= me.toolCoin);
        me.toolCoin -= amount;
        me.serviceCoin += amount;
    }

    function offerService(uint price, string memory _serviceContent) public {
        require(isRegister[msg.sender]);
        ToolMan storage offer = toolman[msg.sender];
        offer.servicePrice.push(price);
        offer.serviceContent.push(_serviceContent);
        offer.servicekind += 1;
        //Servicelistupdate();

        emit getserviceoffer (msg.sender, _serviceContent, price);
    }
    
    function serviceAccept (address lazyman) public{
        require(callingService[msg.sender][lazyman] == true);
        beaskserving[msg.sender][lazyman] = true;
        emit serviceAccepted(msg.sender, lazyman);
    }
    
    function serviceFinished(address addrTool, uint number, uint score) public {
        // msg.sender is lazyman
        require(callingService[addrTool][msg.sender] == true);
        require(beaskserving[addrTool][msg.sender] == true);
        beaskserving[addrTool][msg.sender] = false;
        callingService[addrTool][msg.sender] = false;
        number = numberService[addrTool][msg.sender];
        require(isRegister[msg.sender]);
        require(isRegister[addrTool]);
        require(score <= maxScore);
        uint price;
        uint finalPrice;
        ToolMan storage sender = toolman[msg.sender];
        ToolMan storage tool = toolman[addrTool];
        price = tool.servicePrice[number-1];
        finalPrice = price * score / maxScore;
        
        sender.giveServiceScore.push(score);
        antiWashingCoin[addrTool][msg.sender] += finalPrice;
        tool.toolCoin += finalPrice;
        tool.serviceCoin += price - finalPrice;
        tool.receivedServiceScore.push(score);
    
        uint i;
        uint highest;
        uint washing100;
        washing100 = 0;
        for (i=0;i<addressbook.length;i++){
            washing100 += antiWashingCoin[addrTool][addressbook[i]];
            if (highest < antiWashingCoin[addrTool][addressbook[i]]){
                highest = antiWashingCoin[addrTool][addressbook[i]];
            }
        }
        washing100 = highest * 100 / (washing100 + 1);//防除以0;
        //ToolMan storage tool = toolman[addrTool];
        tool.washingIndex = washing100;
        
        emit finishService(msg.sender, addrTool, tool.serviceContent[number-1], price, score);
    }
    
    function getmycalling(address addr) public view returns(
        bool callingsomeone){
            callingsomeone = callingService[addr][msg.sender];
            //callingsomeoneD = callingDating[addr][msg.sender];
    } 
        
    function getmybecalled(address addr) public view returns(
        bool becalledsomeone){
            becalledsomeone = callingService[msg.sender][addr];
    }   
        
    function getToolManInfo(address addr) public view returns (
        uint[] memory meanReceivedService,
        uint[] memory meanReceivedDating,
        uint[] memory meanGiveService ,
        uint[] memory meanGiveDating,
        uint datingPrice,
        uint gender,
        uint washingIndex,
        uint bidFriendFee,
        string memory id
        ) {

        ToolMan storage tool = toolman[addr];
        meanReceivedService = tool.receivedServiceScore;
        meanReceivedDating = tool.receivedDatingScore;
        meanGiveService = tool.giveServiceScore;
        meanGiveDating = tool.giveDaingScore;
        datingPrice = tool.datingPrice;
        gender = tool.gender;
        washingIndex = tool.washingIndex;
        bidFriendFee = friendRequest[addr][msg.sender]; //疑似疑似寫反
        id=tool.id;
    }

    function getmyinfo() public view returns (
        uint serviceCoin, uint toolCoin) {
        ToolMan storage tool = toolman[msg.sender];
        serviceCoin = tool.serviceCoin;
        toolCoin = tool.toolCoin;
    }

    function getmyservice(uint number)public view returns(uint price, string memory content){
        ToolMan storage tool = toolman[msg.sender];
        price=tool.servicePrice[number-1];
        content=tool.serviceContent[number-1];
    }
    //運作區####################################################################################
    
    //暫緩區####################################################################################
    function updateMyInfo(uint datingPrice, string memory _selfintro) public {
        require(isRegister[msg.sender]);
        ToolMan storage dater = toolman[msg.sender];
        dater.datingPrice = datingPrice;
        dater.selfIntro.push(_selfintro);
        dater.selfIntroVersion += 1;
         //Servicelistupdate();
        emit getupdateIntro (msg.sender, _selfintro, datingPrice);
    }
    
    function updateMySecret(string memory phone, string memory otherinfo) public {
        require(isRegister[msg.sender]);
        ToolMan storage dater = toolman[msg.sender];
        dater.phoneNumber = phone;
        dater.secret = otherinfo;
        //Servicelistupdate();
    }
    
    function cancellService(uint number) public{
        require(isRegister[msg.sender]);
        ToolMan storage offer = toolman[msg.sender];
        emit cancellServiceOffer (msg.sender, offer.serviceContent[number-1],offer.servicePrice[number-1]);
        offer.servicePrice[number-1] = offer.servicePrice[offer.servicekind-1];
        offer.serviceContent[number-1] = offer.serviceContent[offer.servicekind-1];
        offer.servicePrice.length -=1;
        offer.serviceContent.length -=1;
        offer.servicekind -= 1;
        // Servicelistupdate();
    }
    
    function callSpecificDating (address dater) public{ //需有Price之32倍工具人幣才能使用此功能
     require(callingDating[dater][msg.sender] == false);
        ToolMan storage goodpartner = toolman[dater];
        ToolMan storage tool = toolman[msg.sender];
        uint price;
        price = goodpartner.datingPrice * 32;
        require(tool.toolCoin > price);        
        tool.toolCoin -= price;
        callingDating[dater][msg.sender] = true; 
        emit callDating(dater);
    }
    
    function datingAccept (address addrTool) public{
        require(callingDating[msg.sender][addrTool] == true);
        bedating[msg.sender][addrTool]= true;
        emit datingAccepted(msg.sender, addrTool);
    }
    
    function withdrawToolman(uint amount) public payable {
        require(isRegister[msg.sender]);
        ToolMan storage me = toolman[msg.sender];
        require(amount <= me.serviceCoin);
        require(amount <= contractAsset);

        me.serviceCoin -= amount;
        contractAsset -= amount;
        msg.sender.transfer(amount);
    }

    function abs(int val) private pure returns (uint) {
        if (val < 0) {
            return uint(val * -1) ;
        }
        return uint(val);
    }

    function datingFinished(address addrMate, uint score) public {
        require(isRegister[msg.sender]);
        require(isRegister[addrMate]);
        require(bedating[addrMate][msg.sender] == true);
        
        require(score <= maxScore);
        ToolMan storage sender = toolman[msg.sender];
        ToolMan storage mate = toolman[addrMate];
        uint price;
        price = mate.datingPrice;
        sender.toolCoin += price * 32;
        uint modifiedScore = 2 ** abs(int(score) - int(maxScore) / 2);
        //require(sender.toolCoin >= price * modifiedScore);
        sender.toolCoin -= price * modifiedScore;
        sender.giveDaingScore.push(score);
        contractServiceCoin += price * (modifiedScore - 1);

        mate.serviceCoin += price;
        mate.receivedDatingScore.push(score);
        bedating[addrMate][msg.sender] = false;
        
        emit finishDating(msg.sender, addrMate, price, score);
    }

    function addFriend(address addr, uint price) public {
        require(isRegister[msg.sender]);
        require(isRegister[addr]);
        require(friends[msg.sender][addr] == false);
        require(price >= friendFee);
        if (friendRequest[addr][msg.sender] > 0) {
            ToolMan storage accepter = toolman[msg.sender];
            //ToolMan storage sender = toolman[addr];
            accepter.serviceCoin += friendRequest[addr][msg.sender] - friendFee;
            contractServiceCoin -= friendRequest[addr][msg.sender] - friendFee;
            friendRequest[addr][msg.sender] = 0;
            friends[msg.sender][addr] = true;
            friends[addr][msg.sender] = true;

        } else {
            ToolMan storage sender = toolman[msg.sender];
            require(sender.toolCoin >= price);
            sender.toolCoin -= price;
            contractServiceCoin += price;
            friendRequest[msg.sender][addr] += price;
        }
    }

    function getMateInfo(address addr) public view returns(uint nowisdating){
        uint i;
        nowisdating = 0;
        for (i=0;i<addressbook.length;i++){
            if(bedating[addr][addressbook[i]] == true){
                nowisdating += 1;
            }
        }
    }
    
    function getWashingIndex (address addr) public returns(uint washing100){
        uint i;
        uint highest;
        washing100 = 0;
        for (i=0;i<addressbook.length;i++){
            washing100 += antiWashingCoin[addr][addressbook[i]];
            if (highest < antiWashingCoin[addr][addressbook[i]]){
                highest = antiWashingCoin[addr][addressbook[i]];
            }
        }
        washing100 = highest * 100 / (washing100 + 1);//防除以0;
        ToolMan storage tool = toolman[addr];
        tool.washingIndex = washing100;
        if (washing100 > 50 ){
            washingAddress.push(addr);
        }
    }
    
    function getFriendInfo(address addr) public view returns(
        string memory phoneNumber,
        string memory secret
    ){
        require(friends[msg.sender][addr] == true);    
        ToolMan storage friend = toolman[addr];
        phoneNumber = friend.phoneNumber;
        secret = friend.secret;
    }

    function getContractInfo() public view returns (
        uint serviceCoin, uint asset) {
        serviceCoin = contractServiceCoin;
        asset = contractAsset;
    }

    function buyServiceCoin(address dest) public payable {
        require(isRegister[dest]);
        ToolMan storage tool = toolman[dest];
        tool.serviceCoin += msg.value * 9 / 10;
        contractServiceCoin += msg.value - msg.value * 9 / 10;
        contractAsset += msg.value;
    }

    function buyContractService(uint amount) public payable {
        require(isRegister[msg.sender]);
        ToolMan storage tool = toolman[msg.sender];
        require(amount <= tool.toolCoin);
        tool.toolCoin -= amount;
        contractServiceCoin += amount;
    }
    //暫緩區####################################################################################
}
