module Parser
    (
        Binop(..),
        Unop(..),
        Expr(..),
        ArgList(..),
        parseAssemblerFile
    ) where

import Data.List (intercalate)
import Control.Monad (liftM)
import System.IO
import Text.ParserCombinators.Parsec
import Text.Parsec.String
import Text.Parsec.Char
import Text.Parsec.Error
import Text.Regex as R

data Binop =      SET 
                | ADD 
                | SUB 
                | MUL 
                | DIV 
                | MOD 
                | SHL 
                | SHR 
                | AND 
                | BOR 
                | XOR 
                | IFE 
                | IFN 
                | IFG 
                | IFB  
                    deriving Show

data Unop = JSR deriving Show

data ArgList =   BinArg Expr Expr 
               | OneArg Expr
                    deriving Show

data Expr =   Register String
            | MemLocation String
            | MemOffset String String
            | Address String
            | Literal String
            | Error String         --used internally by assembler
            | Bin Binop ArgList
            | Un Unop ArgList
            | Label String [Expr]
            | LabelRef String
            | Comment String
                    deriving Show

hexLiteral = do
    c1 <- char '0'
    c2 <- char 'x'
    c3 <- manyTill hexDigit (oneOf ", " <|> lookAhead newline)
    if (read (c1:c2:c3) :: Int) < 32 then
        return (Literal (c1:c2:c3))
        else return (Address (c1 : c2 : c3))

decLiteral = do
    c1 <- manyTill digit (oneOf ", " <|> lookAhead newline)
    if (read c1 :: Int) < 32 then
        return (Literal c1)
        else return (Address c1)

regList = [string "A", string "B", string "C", string "X", string "Y",
           string "Z", string "I", string "J", string "PC", string "SP",
           string "O"]

memOffset = do
    char '['
    c1 <- char '0'
    c2 <- char 'x'
    c3 <- manyTill hexDigit (char '+')
    reg <- choice regList 
    char ']'
    oneOf ", " <|> lookAhead newline
    return (MemOffset (c1:c2:c3) reg)

memLoc = do
    char '['
    loc <- manyTill anyChar (char ']') 
    oneOf ", " <|> lookAhead newline
    return (MemLocation loc)

reg = do
    r <- choice regList
    oneOf ", " <|> lookAhead newline
    return (Register r)

labelRef = do
    lbl <- manyTill letter (oneOf ", " <|> lookAhead newline)
    return (LabelRef lbl)

ident = (try memOffset) <|> memLoc <|> (try decLiteral) 
            <|> hexLiteral  <|> reg <|> labelRef

arglist = do
    id1 <- ident
    --hacky way to figure out if there's only one argument
    id2 <- option (Register "NULL") ident
    case id2 of
        (Register "NULL") -> return (OneArg id1)
        otherwise         -> return (BinArg id1 id2)

--TODO: think of a more efficient way to do this
cmdList = [try (string "IFE "), try (string "ADD "), try (string "MOD "), 
           try (string "SET "), try (string "IFN "), try (string "DIV "),
           try (string "SHL "), try (string "MUL "), try (string "IFG "),
           try (string "SUB "), try (string "XOR "), try (string "BOR "),
           try (string "IFB "), try (string "AND "), try (string "SHR "),
           try (string "JSR ")]

cmd = do
    c <- choice cmdList
    args <- arglist
    newline
    case c of
        "IFE " -> return (Bin IFE args)
        "IFN " -> return (Bin IFN args)
        "IFG " -> return (Bin IFG args)
        "IFB " -> return (Bin IFB args)
        "ADD " -> return (Bin ADD args)
        "DIV " -> return (Bin DIV args)
        "SUB " -> return (Bin SUB args)
        "AND " -> return (Bin AND args)
        "MOD " -> return (Bin MOD args)
        "SHL " -> return (Bin SHL args)
        "XOR " -> return (Bin XOR args)
        "SHR " -> return (Bin SHR args)
        "SET " -> return (Bin SET args)
        "MUL " -> return (Bin MUL args)
        "BOR " -> return (Bin BOR args)
        "JSR " -> return (Un JSR args)

asmLabel = do
    starter <- char ':'
    name <- manyTill letter space
    cmds <- manyTill (spaces >> cmd) newline
    return (Label name cmds)

assemblerFile = manyTill (spaces >> (cmd <|> asmLabel)) eof

commentRegex = R.mkRegexWithOpts "[ ]*;.*" True False 
removeComments line = R.subRegex commentRegex line ""

argsRegex = R.mkRegexWithOpts ",[ ]+" True False
regularizeArgs line = R.subRegex argsRegex line ","

whitespaceRegex = R.mkRegexWithOpts "^[ ]*" True False
removeLeadWS line = R.subRegex whitespaceRegex line ""

preprocessor :: String -> String
preprocessor line = (regularizeArgs . removeLeadWS . removeComments) line

preprocess :: String -> String
preprocess inp = intercalate "\n" $ map preprocessor $ lines inp

parseAssembler :: String -> Either ParseError [Expr]
parseAssembler input = parse assemblerFile "(syntax error)" $ preprocess input

parseAssemblerFile path = do
    contents <- readFile path
    case parseAssembler contents of
        Left err -> return [(Error (show err))]
        Right parsed -> return parsed