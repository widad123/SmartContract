  
pragma solidity ^0.5.16;

//import "github.com/OpenZeppelin/openzeppelin-contract/contracts/GSN/Context.sol";
//import "github.com/OpenZeppelin/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
//import "github.com/OpenZeppelin/openzeppelin-contracts/contracts/token/ERC20/ERC20Detailed.sol";
//import "@openzeppelin/contracts/math/SafeMath.sol";
//import "@openzeppelin/contracts/GSN/Context.sol";

import "@OpenZeppelin/contracts/token/ERC20/ERC20.sol";
//import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";


contract ArtipToken is   ERC20  {
    string public name = 'ArtipToken';
    string public symbol = 'ARTIP';
    uint public decimals = 18;
   /* constructor () public ERC20Detailed("ArtipToken", "ARTIP", 18) {
        _mint(_msgSender(), 1 * (10 ** uint256(decimals())));
    }*/

}
contract ArtipCrowdSale is ArtipToken {
	// stocke la date de début du PreSale
    uint private datePreSaleStart = 1580598000;
	// stocke la date de fin du PreSale
    uint private datePreSaleEnd = 1593468000;
	// stocke la date de début du Sale
    uint private dateSaleStart = 1593554400;
	// stocke la date de fin du Sale
    uint private dateSaleEnd = 1601416800;
	// stocke la date de début du remboursement
    uint private dateRemboursementStart = 1604185200;
	// stocke la date de fin du remboursement
    uint private dateRemboursementEnd = 1609369200;
	// Minimum requis pour une contribution en PreSale
    uint private minContrubPreSale = 10 ether;
	// Maximum requis pour une contribution en PreSale
    uint private maxContrubPreSale = 1000 ether;
	// Minimum requis pour une contribution en Sale
    uint private minContrubSale = 5 ether;
	// Maxiùmum requis pour une contribution en Sale
    uint private maxContrubSale = 500 ether;
	// Recupère le maximum de Token
    uint private maxArtip = 6000000*10**(18) ;
	//Recupère la réduction à effectué pour une Sale
    uint private preSalReduction = 20; //20%
    // The token being sold
    ArtipToken public  artiptoken;
    // Address where funds are collected
    address payable private _wallet;
    // How many token units a buyer gets per wei.
    uint256 private _rate = 1;
    // Amount of wei raised
    uint256 private _weiRaised;
    //Récupère une whiteList
    mapping(address=>Personne) public whiteliste;
    mapping(address=>uint) private listAcheteurs;
	//Adresse de l'administrateur
    address admin;
    //Structure définit les caractéristiques d'une personne
    struct Personne {
        string nom;
        string prenom;
        address _address;
    }
	//Exige que l'admin soit le détenteur du contrat
    modifier onlyAdmin{
        require(admin == msg.sender, "erreur: not admin");
        _;
    }
    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokensAchete(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    constructor (address payable wallet) public {
        require(wallet != address(0), "ArtipCrowdSale: wallet is the zero address");
        _wallet = wallet;
        artiptoken = new ArtipToken();
        admin = msg.sender;
    }
    // Fonction pour acheter des tokens
    function TokensAchete() public  payable {
        //le montant a payer en wei
        uint256 weiAmount = msg.value;
		//Adresse du beneficiaire
        address beneficiary = msg.sender;
        uint256 artip;
		//On valide le beneficiaire et le montant
        _premiereValidation(beneficiary, weiAmount);
        //Si le beneficiaire est dans la WhiteList et que date du jour est comprise dans les dates de PreSale
        if (whiteliste[msg.sender]._address == msg.sender && now < datePreSaleEnd){
			//Alors, on valide le montant en Wei
            _preSaleValidation(weiAmount);
			// On récupère le montant en Wei auquel on ajoute la réduction de 20%
            artip = _getTokenAmount(weiAmount+weiAmount.mul(preSalReduction).div(100));
        } else {
             _SaleValidation(weiAmount);
			 //Sinon on récupère le montant en Wei
             artip = _getTokenAmount(weiAmount);
        }
        _weiRaised = _weiRaised.add(weiAmount);
        _envoieTokens(beneficiary,artip);
        _forwardFunds();
        listAcheteurs[msg.sender].add(weiAmount);
    }
    // Fonction de rembourssement
    function remboursement() public {
		//On exige que le remboursement soit effectué durant l'intervalle de dates données
        require(now >= dateRemboursementStart && now <= dateRemboursementEnd,"Remboursement non disponible actuellement");
		//On exige que seulement les personnes dans la Liste des acheteurs puisse avoir un reboursement
        require(listAcheteurs[msg.sender]>0, "rien a rembourser");
		// Permet d'envoyer des tokens vers un acheteur
        transfer(msg.sender, listAcheteurs[msg.sender]);
		//Ajoute les wei de l'acheteur dans les wei amassés
        _weiRaised.sub(listAcheteurs[msg.sender]);
        listAcheteurs[msg.sender] = 0;
    }
    // Fonction qui permet de valider le beneficiaire et le montant de la transaction
    function _premiereValidation(address beneficiary, uint256 weiAmount) public  view {
		//Exige de ne pas dépasser le maximum de Artip disponible
        require(artiptoken.totalSupply() < maxArtip, "le maximum de artip est atteint");
		//Exige que le beneficiaire a une adresse différente de zéro
        require(beneficiary != address(0), "ArtipCrowdsale: beneficiary is the zero address");
		//Exige que le montant de Wei disponible soit non-nul
        require(weiAmount != 0, "ArtipCrowdsale: weiAmount is 0");
		//Exige que les dates de PreSale soient respectées
        require(now >= datePreSaleStart && now <= dateSaleEnd,"sale expiré !");
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }
	//Fonction qui valide les paramètres du PreSale
    function _preSaleValidation(uint256 weiAmount) public  view {
		//Exige que le montant de Wei soit compris dans l'intervalle du montant de Contribution PreSale
        require(weiAmount >= minContrubPreSale && weiAmount <= maxContrubPreSale,"Montant non valide");
		//Exige que lorsqu'on ajoute le montant de Wei, il ne dépasse pas le maximum de Artip disponible
        require(artiptoken.totalSupply().add(weiAmount) < maxArtip, "le maximum de artip est atteint");
        this;
    }
    //Fonction qui valide les paramètres du Sale
    function _SaleValidation(uint256 weiAmount) public  view {
		//Exige que le montant de Wei soit compris dans l'intervalle de Contribution Sale
        require(weiAmount >= minContrubSale && weiAmount <= maxContrubSale,"montant non valide");
		//Exige que le montant de total ne dépasse le maximum de Artip disponible
        require(artiptoken.totalSupply().add(weiAmount) < maxArtip, "le maximum de artip est atteint");
		//Exige que la date actuelle soit égale à la date de début du Sale
        require(now >= dateSaleStart,"sale non disponible");
        this;
    }
    //Fonction qui envoie les token vers le beneficiaire
    function _envoieTokens(address beneficiary, uint256 tokenAmount) public  {
        artiptoken.transfer(beneficiary, tokenAmount);
    }
    //Récupère les Token pour y appliquer le taux de change
    function _getTokenAmount(uint256 weiAmount) public  view returns (uint256) {
        return weiAmount.mul(_rate);
    }
    /**
     * @dev Determines how ETH is stored/forwarded on purchases.
     */
    function _forwardFunds() public payable  {
        _wallet.transfer(msg.value);
    }
    //Ajoute une personne à la WhiteList
    function ajouterPersonne (string memory _nom, string memory _prenom, address _address) public onlyAdmin {
		// Création d'une nouvelle personne
        Personne memory p = Personne(_nom, _prenom, _address);
		//Ajout de la nouvelle personne dans la WhiteList
        whiteliste[_address] = p;
    }
}