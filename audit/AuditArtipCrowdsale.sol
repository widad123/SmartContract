pragma solidity 0.6.0;  

/// @titre: Audit smart contract  ArtipCrowdSale
/// @auteur: Widad Ait oufkir
/// @notice : Optimisation du contrat  ArtipCrowdSale

/// @notice: importation différentes libriraies utiliisé par  ArtipCrowdSale
import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol';
import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol';





// Contract ArtipToken qui utilise l'interface ERC20 

contract ArtipToken is   ERC20  {
    string public name = 'ArtipToken';
    string public symbol = 'ARTIP';
    uint256 public decimals = 18;
   /* constructor () public ERC20Detailed("ArtipToken", "ARTIP", 18) {
        _mint(_msgSender(), 1 * (10 ** uint256(decimals())));
    }*/

}


contract ArtipCrowdSale  {
        using SafeMath for uint256;
        //Structure définit les caractéristiques d'une personne
    struct Personne {
        string nom;
        string prenom;
        address _address;
    }  

  // How many token units a buyer gets per wei.
    uint256 private _rate;
    // Amount of wei raised
    uint256 private _weiRaised;
    //Récupère une whiteList
	// stocke la date de début du PreSale
    uint256 private datePreSaleStart ;
	// stocke la date de fin du PreSale
    uint256 private datePreSaleEnd;
	// stocke la date de début du Sale
    uint256 private dateSaleStart ;
	// stocke la date de fin du Sale
    uint256 private dateSaleEnd;
	// stocke la date de début du remboursement
    uint256 private dateRemboursementStart;
	// stocke la date de fin du remboursement
    uint256 private dateRemboursementEnd ;
	// Minimum requis pour une contribution en PreSale
    uint256 private minContrubPreSale ;
	// Maximum requis pour une contribution en PreSale
    uint256 private maxContrubPreSale;
	// Minimum requis pour une contribution en Sale
    uint256 private minContrubSale ;
	// Maxiùmum requis pour une contribution en Sale
    uint256 private maxContrubSale;
	// Recupère le maximum de Token
    uint256 private maxArtip ;
	//Recupère la réduction à effectué pour une Sale
    uint256 private preSalReduction; //20%
    // The token being sold
    ArtipToken private  artiptoken;
    // Address where funds are collected
    address payable private _wallet;
    	//Adresse de l'administrateur
    address private admin;
   
  
    mapping(address=>Personne) private whiteliste;
    mapping(address=>uint256) private listAcheteurs;
    
//constructeur 
 constructor (uint256 rate, uint256 _datePreSaleStart,uint256 _datePreSaleEnd,
    uint256 _dateSaleStart,uint256 _dateSaleEnd,uint256 _dateRemboursementStart,uint256 _dateRemboursementEnd,
    uint256 _minContrubPreSale,uint256 _maxContrubPreSale,uint256 _minContrubSale,uint256 _maxContrubSale,
    uint256 _maxArtip) 
    public {
        require(msg.sender != address(0), "ArtipCrowdSale: wallet is the zero address");
        _wallet = msg.sender;
        admin = msg.sender;
        artiptoken = new ArtipToken();
        _rate=rate;
        datePreSaleStart = _datePreSaleStart;
        datePreSaleEnd = _datePreSaleEnd;
        dateSaleStart = _dateSaleStart;
        dateSaleEnd =_dateSaleEnd ;
        dateRemboursementStart = _dateRemboursementStart;
        dateRemboursementEnd = _dateRemboursementEnd;
        minContrubPreSale = _minContrubPreSale;
        maxContrubPreSale = _maxContrubPreSale;
        minContrubSale =_minContrubSale;
        maxContrubSale = _maxContrubSale;
        maxArtip = _maxArtip*10**(18) ;
    }
	//Exige que l'admin soit le détenteur du contrat
    modifier onlyAdmin{
        require(admin == msg.sender, "erreur: not admin");
        _;
    }
      //verifier si on est tjr on periode de PreSale
    modifier saleTimeVerif(){
         require(now >= datePreSaleStart && now <= dateSaleEnd,"sale expiré !");
        _;
    }
    
     //verifier si on est dans la periode sans promo
   modifier _isSaleTime (){
         require(now >= dateSaleStart && now<=dateSaleEnd,"sale non disponible");
            _;
   }
   
     //verifier si on est dans la periode presale
   modifier _isPreSaleTime (){
         require(now >= datePreSaleStart && now<=datePreSaleEnd,"sale non disponible");
            _;
   }
    
    //On exige que le remboursement soit effectué durant l'intervalle de dates données
    modifier _refundTimeverif(){
        require(now >= dateRemboursementStart && now <= dateRemboursementEnd,"Remboursement non disponible actuellement");
        _;
    }
    
	//Exige que lorsqu'on ajoute le montant de Wei, il ne dépasse pas le maximum de Artip disponible
    modifier _maxArtipReached(uint256 weiAmount){
        require(artiptoken.totalSupply().add(weiAmount) < maxArtip, "le maximum de artip est atteint");
            _;
    }
    
            //Exige que le montant de Wei soit compris dans l'intervalle du montant de Contribution PreSale

    modifier _amountPresale(uint256 weiAmount){
        require(weiAmount >= minContrubPreSale && weiAmount <= maxContrubPreSale,"Montant non valide");
        _;
    }
    
    	//Exige que le montant de Wei soit compris dans l'intervalle de Contribution Sale
    modifier _amountSale(uint256 weiAmount){
        require(weiAmount >= minContrubSale && weiAmount <= maxContrubSale,"montant non valide");
        _;
    	    }
  
    /**
     * Event for token purchase logging
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokensAchete(address beneficiary, uint256 value, uint256 amount);
    event estRembourse();
    
    
    /// @notice Fonction pour acheter des tokens
    function acheterArtipToken() payable external {
        //le montant a payer en wei
        uint256 weiAmount = msg.value;
		//Adresse du beneficiaire
        address  beneficiary = msg.sender;
        uint256 artip;
		//On valide le beneficiaire et le montant
        _premiereValidation(beneficiary, weiAmount);
        //Si le beneficiaire est dans la WhiteList et que date du jour est comprise dans les dates de PreSale
        if (whiteliste[msg.sender]._address == msg.sender){
			//Alors, on valide le montant en Wei
            _preSaleValidation(weiAmount);
			// On récupère le montant en Wei auquel on ajoute la réduction de 20%
            artip = _getTokenAmount(weiAmount+weiAmount.mul(preSalReduction).div(100));
        } else {
             _SaleValidation(weiAmount);
			 //Sinon on récupère le montant en Wei
             artip = _getTokenAmount(weiAmount);
        }
             emit  TokensAchete(beneficiary, weiAmount, artip);

        _weiRaised = _weiRaised.add(weiAmount);
        listAcheteurs[msg.sender].add(weiAmount);
        _forwardFunds();
        artiptoken.transfer(beneficiary, artip);

    }
    
     	    
    /// ànotice Fonction de rembourssement
    function remboursement() 
        internal
        _refundTimeverif {
		//On exige que seulement les personnes dans la Liste des acheteurs puisse avoir un reboursement
        require(listAcheteurs[msg.sender]>0, "rien a rembourser");
        	emit estRembourse();

        uint256 refundAmount=listAcheteurs[msg.sender];
                _weiRaised.sub(listAcheteurs[msg.sender]);
                listAcheteurs[msg.sender] = 0;
		// Permet d'envoyer des tokens vers un acheteur
        artiptoken.transfer(msg.sender, refundAmount);
		//Ajoute les wei de l'acheteur dans les wei amassés
    }
    
    /// @notice Fonction qui permet de valider le beneficiaire et le montant de la transaction
    /// @param beneficiary: l'adresse du beneficiaire weiAmount:le montant à payer en wei
    /// @return bool
    function _premiereValidation(address beneficiary, uint256 weiAmount)
            internal
            view 
            saleTimeVerif
            _maxArtipReached(weiAmount)
            returns(bool){ //peut etre interne
	
		//Exige que le beneficiaire a une adresse différente de zéro
        require(beneficiary != address(0), "ArtipCrowdsale: beneficiary is the zero address");//la longueur de l'adresse
		//Exige que le montant de Wei disponible soit non-nul
        require(weiAmount != 0, "ArtipCrowdsale: weiAmount is 0");
	
        return true;
}
	//
	
    /// @notice Fonction Fonction qui valide les paramètres du PreSale
    /// @param weiAmount:le montant à payer en wei
    /// @return bool 
    function _preSaleValidation(uint256 weiAmount) 
            internal 
            view
             _isPreSaleTime
            _amountPresale(weiAmount)
            _maxArtipReached(weiAmount)
             returns(bool)
    {
	       return true;
    }
    
    /// @notice Fonction qui valide les paramètres du Sale
    /// @param weiAmount:le montant à payer en wei
    /// @return bool 
    function _SaleValidation(uint256 weiAmount)
            internal 
            view
            _isSaleTime
            _amountSale(weiAmount)
            _maxArtipReached(weiAmount)
            returns(bool){
        return true;
    }
    
    /// @notice Fonction qui envoie les token vers le beneficiaire
    /// @param beneficiary: l'adresse du beneficiaire weiAmount:le montant à payer en wei
    function _envoieTokens(address beneficiary, uint256 tokenAmount) internal {
        artiptoken.transfer(beneficiary, tokenAmount);
    }
    
     /// @notice Fonction Récupère les Token pour y appliquer le taux de change
    /// @param weiAmount:le montant à payer en wei
    /// @return uint256 qui correspond aux nombres de tokens
    
    function _getTokenAmount(uint256 weiAmount) internal  view returns (uint256) {
        return weiAmount.mul(_rate);
    }
    /**
     * @dev Determines how ETH is stored/forwarded on purchases.
     */
     
    function _forwardFunds() public payable {
        require(msg.data.length == 0);
        _wallet.transfer(msg.value);
    }
    
    /// @notice Fonction pour Ajoute une personne à la WhiteList
    /// @param _nom ,_prenom, _address de la personne à ajouter 
    function ajouterPersonne (string memory _nom, string memory _prenom, address _address) internal onlyAdmin {
		// Création d'une nouvelle personne
        Personne memory p = Personne(_nom, _prenom, _address);
		//Ajout de la nouvelle personne dans la WhiteList
        whiteliste[_address] = p;
    }
}
