"use client";

import { useEffect, useState } from "react";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { BadgeCheck, ChevronRight, Ticket, X } from "lucide-react";
import { useOrderStore, useProductStore } from "@/store";
import { motion, AnimatePresence } from "framer-motion";
import { toast } from "sonner";
import { useTranslations } from "next-intl";
import {
  formatNumber,
  getLocalizedCategoryName,
  getLocalizedProduct,
  posterUrl,
} from "@/lib/utils";
import Image from "next/image";

export default function PromoCodeDialog({
  auth,
  locale,
  promotions,
  productsData,
  categoriesData,
}) {
  const promocodeT = useTranslations("Order.Promocode");
  const all = useTranslations("All");
  const [promoCode, setPromoCode] = useState("");
  const [isOpen, setIsOpen] = useState(false);
  const { orderData, setOrderData, totalSum } = useOrderStore();
  const { products, setProductsData } = useProductStore();
  const [error, setError] = useState(null);
  const [hovered, setHovered] = useState(true);
  const [addingProducts, setAddingProducts] = useState([]);
  const [promotionPrice, setPromotionPrice] = useState(0);
  const [promotionDiscount, setPromotionDiscount] = useState(0);
  console.log({ promotions });
  console.log({ auth });

  const handleRemovePromo = () => {
    setOrderData({
      ...orderData,
      promocode: null,
      promocodePrice: 0,
      discountPromocode: 0,
    });
    setProductsData(products?.filter((product) => !product?.promocode));
    setPromoCode("");
    setIsOpen(false);
    setHovered(false);
    setPromotionDiscount(0);
    toast(promocodeT("success_del"), {
      type: "success",
      duration: 2000,
    });
  };

  const handleApply = () => {
    if (!promoCode) {
      setError({
        title: promocodeT("input_pls"),
        type: "invalid_code",
      });
      return;
    }
    if (orderData?.promocode) {
      setError({
        title: promocodeT("already_use"),
        type: "invalid_code",
      });
      return;
    }
    let findPromo = promotions.find((promo) => {
      const promoCodeFind = promo?.name?.split("$")[1];
      if (
        String(promoCodeFind).toLowerCase().trim() ===
        String(promoCode).toLowerCase().trim()
      ) {
        return true;
      }
      return false;
    });
    const filterProducts = productsData
      ?.filter((product) => {
        const findProduct = findPromo?.params?.bonus_products?.find(
          (pr) => pr?.id === product?.product_id
        );
        return !!findProduct;
      })
      ?.map((prd) => ({
        ...prd,
        promocode: findPromo,
        count: findPromo?.params?.bonus_products_pcs,
      }));

    console.log({ filterProducts });

    if (findPromo) {
      //Only for auth users
      if (!auth?.client_id && findPromo?.params?.clients_type == 3) {
        setError({
          title: promocodeT("error_auth"),
          type: "invalid_code",
        });
        return;
      }
      let nameProducts = "";
      const conditionsProducts = findPromo?.params?.conditions;
      console.log({ categoriesData, productsData });
      conditionsProducts?.forEach((condition) => {
        switch (condition?.type) {
          case 1: // Category
            const findP = categoriesData.find(
              (pr) => pr.category_id == condition?.id
            );
            console.log({ findP });
            if (findP) {
              const localizedNameCategory = getLocalizedCategoryName(
                findP?.category_name,
                locale
              );
              nameProducts += `${(
                condition?.sum / 100
              )?.toLocaleString()} ${promocodeT(
                "error_min_sum"
              )} - ${localizedNameCategory} `;
            }
            break;
          case 2: // Product
            const findPr = productsData.find(
              (pr) => pr.product_id == condition?.id
            );

            if (findPr) {
              const localizedName = getLocalizedProduct(
                findPr?.product_production_description,
                locale,
                "name"
              );
              nameProducts += `${(
                condition?.sum / 100
              )?.toLocaleString()} ${promocodeT(
                "error_min_sum"
              )} - ${localizedName} `;
            }
            break;
          default:
            nameProducts = "";
        }
      });
      let isCHeck = false;
      let resultPromo = findPromo;

      conditionsProducts?.forEach((condition) => {
        // if (isCHeck) return; // If already checked, skip further checks
        switch (condition.type) {
          case 0: // All products
            if (totalSum >= condition?.sum / 100) {
              console.log("All products promotion active");
              //Summa promotion
              isCHeck = true; 
              if (
                findPromo?.params?.discount_value > 0 &&
                findPromo?.params?.result_type == 2
              ) {
                resultPromo = {
                  ...resultPromo,
                  params: {
                    ...resultPromo.params,
                    conditions: resultPromo?.params?.conditions?.map((cond) => {
                      if (cond?.id == condition?.id) {
                        return {
                          ...cond,
                          active: true,
                        };
                      }
                      return cond;
                    }),
                  },
                };

                setOrderData({
                  ...orderData,
                  promocode: resultPromo,
                  promocodePrice: findPromo?.params?.discount_value / 100,
                });
                setPromoCode("");
                setHovered(false);
                setError(null);
                toast(promocodeT("success"), {
                  type: "success",
                  duration: 2000,
                });
                setPromotionPrice(findPromo?.params?.discount_value / 100);
              } else if (
                findPromo?.params?.discount_value > 0 &&
                findPromo?.params?.result_type == 3
              ) {
                //Discount promotion
                const today = new Date();
                const birthday = new Date(auth?.birthday);
                const commentC = auth?.comment
                  ? JSON.parse(auth?.comment)
                  : null;
                const promocodeName = String(findPromo?.name?.split("$")[1])
                  .toLowerCase()
                  .trim();
                console.log({ findPromo, promocodeName });

                //Birthday
                if (
                  today.getMonth() === birthday.getMonth() &&
                  today.getDate() === birthday.getDate() &&
                  promocodeName == "bday20"
                ) {
                  resultPromo = {
                    ...resultPromo,
                    params: {
                      ...resultPromo.params,
                      conditions: resultPromo?.params?.conditions?.map(
                        (cond) => {
                          if (cond?.id == condition?.id) {
                            return {
                              ...cond,
                              active: true,
                            };
                          }
                          return cond;
                        }
                      ),
                    },
                  };
                  console.log("birthday active");
                  setOrderData({
                    ...orderData,
                    promocode: resultPromo,
                    discountPromocode: Number(
                      findPromo?.params?.discount_value
                    ),
                  });
                  setPromotionDiscount(
                    Number(findPromo?.params?.discount_value)
                  );
                  setPromoCode("");
                  setHovered(false);
                  setError(null);
                  toast(promocodeT("success"), {
                    type: "success",
                    duration: 2000,
                  });
                } else if (
                  (today.getMonth() !== birthday.getMonth() ||
                    today.getDate() !== birthday.getDate()) &&
                  promocodeName == "bday20"
                ) {
                  setError({
                    title: promocodeT("error_bday"),
                    type: "invalid_code",
                  });
                }

                //First Order
                if (
                  (commentC?.length == 0 || !commentC?.length) &&
                  promocodeName == "first20"
                ) {
                  resultPromo = {
                    ...resultPromo,
                    params: {
                      ...resultPromo.params,
                      conditions: resultPromo?.params?.conditions?.map(
                        (cond) => {
                          if (cond?.id == condition?.id) {
                            return {
                              ...cond,
                              active: true,
                            };
                          }
                          return cond;
                        }
                      ),
                    },
                  };
                  setOrderData({
                    ...orderData,
                    promocode: resultPromo,
                    discountPromocode: Number(
                      findPromo?.params?.discount_value
                    ),
                  });
                  setPromotionDiscount(
                    Number(findPromo?.params?.discount_value)
                  );
                  setPromoCode("");
                  setHovered(false);
                  setError(null);
                  toast(promocodeT("success"), {
                    type: "success",
                    duration: 2000,
                  });
                } else if (commentC?.length > 0 && promocodeName == "first20") {
                  setError({
                    title: promocodeT("error_first20"),
                    type: "invalid_code",
                  });
                }

                //Default
                if (promocodeName != "bday20" && promocodeName != "first20") {
                  resultPromo = {
                    ...resultPromo,
                    params: {
                      ...resultPromo.params,
                      conditions: resultPromo?.params?.conditions?.map(
                        (cond) => {
                          if (cond?.id == condition?.id) {
                            return {
                              ...cond,
                              active: true,
                            };
                          }
                          return cond;
                        }
                      ),
                    },
                  };
                  setOrderData({
                    ...orderData,
                    promocode: resultPromo,
                    discountPromocode: Number(
                      findPromo?.params?.discount_value
                    ),
                  });
                  setPromotionDiscount(
                    Number(findPromo?.params?.discount_value)
                  );
                  setPromoCode("");
                  setHovered(false);
                  setError(null);
                  toast(promocodeT("success"), {
                    type: "success",
                    duration: 2000,
                  });
                }
              } else if (findPromo?.params?.result_type == 1) {
                //Bonus product promotion
                resultPromo = {
                  ...resultPromo,
                  params: {
                    ...resultPromo.params,
                    conditions: resultPromo?.params?.conditions?.map((cond) => {
                      if (cond?.id == condition?.id) {
                        return {
                          ...cond,
                          active: true,
                        };
                      }
                      return cond;
                    }),
                  },
                };
                setAddingProducts(filterProducts);
                setProductsData([...products, ...filterProducts]);
                setError(null);
                setOrderData({ ...orderData, promocode: resultPromo });
                toast(promocodeT("success"), {
                  type: "success",
                  duration: 2000,
                });
                setPromoCode("");
                setHovered(false);
              }
            } else {
              setError({
                title: `${(
                  condition?.sum / 100
                )?.toLocaleString()} ${promocodeT("error_min_sum")}`,
                type: "invalid_code",
              });
            }
            break;
          case 1: // Category
            const findCategoryData = products?.find(
              (prd) => prd?.menu_category_id == condition.id
            );

            const allSummaCategory =
              (findCategoryData?.price["1"] / 100) * findCategoryData?.count;
            if (findCategoryData && allSummaCategory >= condition?.sum / 100) {
              console.log("Category promotion active");
              isCHeck = true;
              if (
                findPromo?.params?.discount_value > 0 &&
                findPromo?.params?.result_type == 2
              ) {
                setOrderData({
                  ...orderData,
                  promocode: findPromo,
                  promocodePrice: findPromo?.params?.discount_value / 100,
                });
                setPromoCode("");
                setHovered(false);
                setError(null);
                toast(promocodeT("success"), {
                  type: "success",
                  duration: 2000,
                });
                setPromotionPrice(findPromo?.params?.discount_value / 100);
              } else if (
                findPromo?.params?.discount_value > 0 &&
                findPromo?.params?.result_type == 3
              ) {
                //Discount promotion
                setOrderData({
                  ...orderData,
                  promocode: findPromo,
                  discountPromocode: Number(findPromo?.params?.discount_value),
                });
                setPromotionDiscount(Number(findPromo?.params?.discount_value));
                setPromoCode("");
                setHovered(false);
                setError(null);
                toast(promocodeT("success"), {
                  type: "success",
                  duration: 2000,
                });
              } else if (findPromo?.params?.result_type == 1) {
                //Bonus product promotion
                setAddingProducts(filterProducts);
                setProductsData([...products, ...filterProducts]);
                setError(null);
                setOrderData({ ...orderData, promocode: findPromo });
                toast(promocodeT("success"), {
                  type: "success",
                  duration: 2000,
                });
                setPromoCode("");
                setHovered(false);
              }
            } else {
              isCHeck = false;
              setError({
                title: `${nameProducts}`,
                type: "invalid_code",
              });
            }
            break;
          case 2: // Product
            const findProductsData = products?.find(
              (prd) => prd?.product_id == condition.id
            );

            const allSummaProducts =
              (findProductsData?.price["1"] / 100) * findProductsData?.count;
            if (findProductsData && allSummaProducts >= condition?.sum / 100) {
              isCHeck = true;
              console.log("Products promotion active");
              if (
                findPromo?.params?.discount_value > 0 &&
                findPromo?.params?.result_type == 2
              ) {
                resultPromo = {
                  ...resultPromo,
                  params: {
                    ...resultPromo.params,
                    conditions: resultPromo?.params?.conditions?.map((cond) => {
                      if (cond?.id == condition?.id) {
                        return {
                          ...cond,
                          active: true,
                        };
                      }
                      return cond;
                    }),
                  },
                };
                setOrderData({
                  ...orderData,
                  promocode: resultPromo,
                  promocodePrice: findPromo?.params?.discount_value / 100,
                });
                setPromoCode("");
                setHovered(false);
                setError(null);
                toast(promocodeT("success"), {
                  type: "success",
                  duration: 2000,
                });
                setPromotionPrice(findPromo?.params?.discount_value / 100);
              } else if (
                findPromo?.params?.discount_value > 0 &&
                findPromo?.params?.result_type == 3
              ) {
                resultPromo = {
                  ...resultPromo,
                  params: {
                    ...resultPromo.params,
                    conditions: resultPromo?.params?.conditions?.map((cond) => {
                      if (cond?.id == condition?.id) {
                        return {
                          ...cond,
                          active: true,
                        };
                      }
                      return cond;
                    }),
                  },
                };
                //Discount promotion
                setOrderData({
                  ...orderData,
                  promocode: resultPromo,
                  discountPromocodeProduct: Number(
                    findPromo?.params?.discount_value
                  ),
                });
                setPromotionDiscount(Number(findPromo?.params?.discount_value));
                setPromoCode("");
                setHovered(false);
                setError(null);
                toast(promocodeT("success"), {
                  type: "success",
                  duration: 2000,
                });
              } else if (findPromo?.params?.result_type == 1) {
                //Bonus product promotion
                setAddingProducts(filterProducts);
                setProductsData([...products, ...filterProducts]);
                setError(null);
                setOrderData({ ...orderData, promocode: findPromo });
                toast(promocodeT("success"), {
                  type: "success",
                  duration: 2000,
                });
                setPromoCode("");
                setHovered(false);
              }
            } else {
              isCHeck = false;
              setError({
                title: `${nameProducts}`,
                type: "invalid_code",
              });
            }
            break;
          default:
            isCHeck = false;
        }
      });
    } else {
      setError({
        title: promocodeT("error"),
        type: "invalid_code",
      });
    }
  };

  const handleClose = () => {
    setIsOpen(false);
    setError(null);
  };

  useEffect(() => {
    if (orderData?.promocode) {
      orderData?.promocode?.params?.conditions?.forEach((condition) => {
        if (!condition?.active) return; // Skip already active conditions
        switch (condition?.type) {
          case 0: // All products
            if (totalSum < condition?.sum / 100) {
              handleRemovePromo();
            }
            break;
          // case 1: // Category
          //   const findCategoryData = products?.find(
          //     (prd) => prd?.menu_category_id == condition.id
          //   );
          //   let allSummaCategory =
          //     (findCategoryData?.price["1"] / 100) * findCategoryData?.count;
          //   if (!allSummaCategory) {
          //     allSummaCategory = 0;
          //   }
          //   console.log({ findCategoryData, allSummaCategory });
          //   if (allSummaCategory < condition?.sum / 100) {
          //     handleRemovePromo();
          //   }
          //   break;
          case 2: // Product
            const findProductsData = products?.find(
              (prd) => prd?.product_id == condition.id
            );

            let allSummaProducts =
              (findProductsData?.price["1"] / 100) * findProductsData?.count;
            if (!allSummaProducts) {
              allSummaProducts = 0;
            }
            console.log({ allSummaProducts, findProductsData });
            if (allSummaProducts < condition?.sum / 100) {
              handleRemovePromo();
            }
            break;
          default:
            break;
        }
      });
    }
  }, [totalSum]);

  return (
    <div className="space-y-2 md:space-y-4">
      <Dialog open={isOpen} onOpenChange={() => {}}>
        <DialogTrigger asChild>
          {orderData?.promocode ? (
            <div
              className="relative group"
              onClick={() => setHovered(!hovered)}
            >
              <Button
                variant="outline"
                className="bg-[#F5F5F5] w-full h-12 flex justify-center items-center gap-1 border-[1px] rounded-xl space-x-2"
              >
                <div className="flex justify-start items-center gap-2">
                  <div>
                    <BadgeCheck className="w-full text-green-500" size={48} />
                  </div>
                  <h1 className="text-green-700 font-medium">
                    {promocodeT("active_promo")}
                  </h1>
                </div>
              </Button>

              <AnimatePresence>
                {hovered && (
                  <motion.div
                    initial={{ opacity: 0, scale: 0.95, y: -5 }}
                    animate={{ opacity: 1, scale: 1, y: 0 }}
                    exit={{ opacity: 0, scale: 0.95, y: -5 }}
                    transition={{ duration: 0.2 }}
                    className="absolute top-2 right-2 flex items-center gap-1 bg-white shadow-md px-2 py-1 rounded-md cursor-pointer border hover:bg-red-100"
                    onClick={handleRemovePromo}
                  >
                    <X className="text-red-500" size={20} />
                    <span className="text-sm text-red-600 font-semibold">
                      {promocodeT("cancel")}
                    </span>
                  </motion.div>
                )}
              </AnimatePresence>
            </div>
          ) : (
            <Button
              onClick={() => setIsOpen(true)}
              variant="outline"
              className="bg-[#F5F5F5] w-full h-10 md:h-12 flex justify-center items-center gap-1 border-[1px] rounded-xl space-x-2"
            >
              <div className="flex justify-start items-center gap-2">
                <div className="transform rotate-45">
                  <Ticket className="w-full text-3xl" size={48} />
                </div>
                <h1>{promocodeT("title")}</h1>
              </div>
              <div className="text-[#2E2E2E]">
                <ChevronRight />
              </div>
            </Button>
          )}
        </DialogTrigger>

        <DialogContent
          handleClose={handleClose}
          mark="false"
          className="max-w-md w-11/12"
        >
          <DialogHeader>
            <DialogTitle className="text-2xl w-full text-start">
              {addingProducts?.length > 0 ||
              promotionPrice > 0 ||
              promotionDiscount > 0 ? (
                <h1>{promocodeT("titleDialogAdd")}</h1>
              ) : (
                <h1>{promocodeT("titleDialog")}</h1>
              )}
            </DialogTitle>
            <DialogDescription />
          </DialogHeader>
          {addingProducts?.length > 0 ? (
            <>
              <div className="overflow-y-scroll flex flex-col w-full simple-scrollbar gap-5">
                {addingProducts
                  ?.slice()
                  ?.reverse()
                  ?.map((item, i) => {
                    const localizedName = getLocalizedProduct(
                      item?.product_production_description,
                      locale,
                      "name"
                    );
                    return (
                      <div
                        key={item.product_id}
                        className="flex gap-2 md:gap-4 mr-4"
                      >
                        <Image
                          src={
                            item?.photo_origin
                              ? `${posterUrl}${item.photo_origin}`
                              : "/empty.jpg"
                          }
                          alt="product"
                          width={100}
                          height={100}
                          className="border max-sm:w-20 max-sm:h-20 object-cover aspect-square rounded-md col-span-2 row-span-2"
                        />
                        <div className="w-full flex flex-col justify-between min-h-16 md:min-h-20 gap-2 md:gap-4 relative">
                          <div className="w-full row-span-1 h-full flex items-start justify-between gap-y-3 gap-1">
                            <p className="font-semibold textSmall3">
                              {localizedName}
                            </p>
                          </div>
                          <div className="col-span-3 row-span-1 flex justify-between item-start sm:items-center">
                            <p className="font-semibold textSmall2 leading-5 w-full">
                              {item?.price["1"]
                                ? `${formatNumber(item.price["1"] / 100)} ${all(
                                    "sum"
                                  )}`
                                : "Price not available"}
                            </p>
                          </div>
                        </div>
                      </div>
                    );
                  })}
              </div>
              <div className="flex justify-end items-end gap-2">
                <Button
                  onClick={() => {
                    setAddingProducts([]);
                    setIsOpen(false);
                    setPromotionPrice(0);
                  }}
                  className="h-10 w-16"
                >
                  OK
                </Button>
              </div>
            </>
          ) : promotionPrice > 0 ? (
            <>
              <div className="flex flex-col w-full simple-scrollbar gap-1">
                <h1 className="textNormal4 font-bold">
                  {promotionPrice?.toLocaleString()} {all("sum")}{" "}
                </h1>
                <p>{all("bonus_price")}</p>
              </div>
              <div className="flex justify-end items-end gap-2">
                <Button
                  onClick={() => {
                    setAddingProducts([]);
                    setIsOpen(false);
                    setPromotionPrice(0);
                  }}
                  className="h-10 w-16"
                >
                  OK
                </Button>
              </div>
            </>
          ) : promotionDiscount > 0 ? (
            <>
              <div className="flex w-full simple-scrollbar justify-start items-center gap-2">
                <h1 className="textNormal4 font-bold">
                  {promotionDiscount?.toLocaleString()}%
                </h1>
                <p>{all("disc")}</p>
              </div>
              <div className="flex justify-end items-end gap-2">
                <Button
                  onClick={() => {
                    setAddingProducts([]);
                    setIsOpen(false);
                    setPromotionPrice(0);
                  }}
                  className="h-10 w-16"
                >
                  OK
                </Button>
              </div>
            </>
          ) : (
            <>
              {/* Input */}
              <div className="space-y-1">
                <Input
                  placeholder={promocodeT("input_pls")}
                  value={promoCode}
                  className={`h-12 ${
                    error ? "border-red-500 focus-visible:ring-red-500" : ""
                  }`}
                  onChange={(e) => {
                    setPromoCode(e.target.value);
                    setError(null);
                  }}
                />

                {/* Error chiqishi */}
                <AnimatePresence>
                  {error && (
                    <motion.p
                      initial={{ opacity: 0, y: -5 }}
                      animate={{ opacity: 1, y: 0 }}
                      exit={{ opacity: 0, y: -5 }}
                      transition={{ duration: 0.25 }}
                      className="text-sm text-red-500 font-medium"
                    >
                      {error.title}
                    </motion.p>
                  )}
                </AnimatePresence>
              </div>

              <Button onClick={handleApply} className="w-full h-12">
                {promocodeT("submit_btn")}
              </Button>
            </>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
